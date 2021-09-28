#!/bin/bash

## Least Privilege Service Account for default node pool
gcloud services enable cloudresourcemanager.googleapis.com
gkeSaName=$clusterName-sa
gkeSaId=$gkeSaName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $gkeSaName \
  --display-name=$gkeSaName
roles="roles/logging.logWriter roles/monitoring.metricWriter roles/monitoring.viewer"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$gkeSaId" --role $r; done
  
## Setup Artifact Registry
gcloud services enable artifactregistry.googleapis.com
containerRegistryName=containers
gcloud artifacts repositories create $containerRegistryName \
    --location $region \
    --repository-format docker
gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
gcloud artifacts repositories add-iam-policy-binding $containerRegistryName \
    --location $region \
    --member "serviceAccount:$gkeSaId" \
    --role roles/artifactregistry.reader

## Setup Binary Authorization
gcloud services enable binaryauthorization.googleapis.com
sed -i "s/REGION/$region/g" ../configs/binauth-policy.yaml
sed -i "s/PROJECT_ID/$projectId/g" ../configs/binauth-policy.yaml
sed -i "s/REGISTRY_NAME/$containerRegistryName/g" ../configs/binauth-policy.yaml
gcloud container binauthz policy import ../configs/binauth-policy.yaml

## Create GKE cluster
gcloud services enable container.googleapis.com
# Delete the default compute engine service account if you don't have have the Org policy iam.automaticIamGrantsForDefaultServiceAccounts in place
projectNumber="$(gcloud projects describe $projectId --format='get(projectNumber)')"
gcloud iam service-accounts delete $projectNumber-compute@developer.gserviceaccount.com --quiet
# Get local IP address to get access to the Kubernetes API (I'm on Crostini)
myIpAddress=$(curl ifconfig.co)
# TODO: remove `beta` as soon as confidential computing is GA.
gcloud beta container clusters create $clusterName \
    --enable-confidential-nodes \
    --enable-binauthz \
    --service-account $gkeSaId \
    --workload-pool=$projectId.svc.id.goog \
    --release-channel rapid \
    --zone $zone \
    --disk-type pd-ssd \
    --machine-type n2d-standard-4 \
    --disk-size 256 \
    --image-type cos_containerd \
    --enable-dataplane-v2 \
    --addons NodeLocalDNS,HttpLoadBalancing \
    --enable-shielded-nodes \
    --shielded-secure-boot \
    --enable-ip-alias \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-stackdriver-kubernetes \
    --max-pods-per-node 30 \
    --default-max-pods-per-node 30 \
    --services-ipv4-cidr '/25' \
    --cluster-ipv4-cidr '/20' \
    --enable-vertical-pod-autoscaling \
    --enable-master-authorized-networks \
    --master-authorized-networks $myIpAddress/32

# Enable Anthos
gcloud services enable anthos.googleapis.com
gcloud container hub memberships register $clusterName \
    --gke-cluster $zone/$clusterName \
    --enable-workload-identity

# ASM
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.10 > install_asm
chmod +x install_asm
cat <<EOF > ingress-backendconfig-operator.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            type: ClusterIP
          serviceAnnotations:
            cloud.google.com/backend-config: '{"default": "ingress-backendconfig"}'
            cloud.google.com/neg: '{"ingress": true}'
EOF
install_asm \
  --project_id $projectId \
  --cluster_name $clusterName \
  --cluster_location $zone \
  --mode install \
  --enable-all \
  --option cloud-tracing \
  --custom_overlay ingress-backendconfig-operator.yaml

## Add labels to kube-system and istio-sytem namespaces, as per https://alwaysupalwayson.com/calico/
# FIXME - put that in https://github.com/mathieu-benoit/my-kubernetes-deployments, we shouldn't do kubectl on this remote GKE cluster, soon private...
kubectl label ns kube-system name=kube-system
kubectl label ns istio-system name=istio-system

# Provision infra specifically per apps (myblog, onlineboutique, bankofanthos) before doing the config sync section below

# Config Sync
gcloud beta container hub config-management enable
cat <<EOF > configsync-config.yaml
applySpecVersion: 1
spec:
  policyController:
    enabled: true
    templateLibraryInstalled: true
  configSync:
    enabled: true
    sourceFormat: hierarchy
    syncRepo: https://github.com/mathieu-benoit/my-kubernetes-deployments
    syncBranch: main
    secretType: none
    policyDir: .
EOF
gcloud beta container hub config-management apply \
  --membership=$clusterName \
  --config=configsync-config.yaml
