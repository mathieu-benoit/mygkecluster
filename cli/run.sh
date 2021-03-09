#!/bin/bash

## Least Privilege Service Account for default node pool
gcloud services enable cloudresourcemanager.googleapis.com
gkeSaName=$clusterName-sa
gkeSaId=$gkeSaName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $gkeSaName \
  --display-name=$gkeSaName
roles="roles/logging.logWriter roles/monitoring.metricWriter roles/monitoring.viewer"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$gkeSaId" --role $r; done
  
## Setup Container Registry
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
# TODO: remove `beta` once confidential computing is GA.
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
    --enable-network-policy \
    --addons NodeLocalDNS,HttpLoadBalancing,ConfigConnector \
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
    --enable-vertical-pod-autoscaling

## Get GKE cluster kubeconfig
gcloud container clusters get-credentials $clusterName \
    --zone $zone

# Enable Anthos
gcloud services enable anthos.googleapis.com
# FIXME: GKE connect, etc.

# ASM
mkdir ~/tmp
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.8 > ~/tmp/install_asm
chmod +x ~/tmp/install_asm
~/tmp/install_asm \
  --project_id $projectId \
  --cluster_name $clusterName \
  --cluster_location $zone \
  --mode install \
  --enable-all
# --option cloud-tracing

## Add labels to kube-system and istio-sytem namespaces, as per https://alwaysupalwayson.com/calico/
kubectl label ns kube-system name=kube-system
kubectl label ns istio-system name=istio-system

# Config Sync
kubectl apply -f ../components/config-management-operator.yaml
sed -i "s/CLUSTER_NAME/$clusterName/g" ../configs/config-management.yaml
kubectl apply -f ../configs/config-management.yaml

# Config Connector
ccSa=configconnector-sa
gcloud iam service-accounts create $ccSa
gcloud projects add-iam-policy-binding $projectId \
    --member="serviceAccount:$ccSa@$projectId.iam.gserviceaccount.com" \
    --role="roles/owner"
# FIXME, shouldn't be `roles/owner`
gcloud iam service-accounts add-iam-policy-binding $ccSa@$projectId.iam.gserviceaccount.com \
    --member="serviceAccount:$projectId.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    --role="roles/iam.workloadIdentityUser"
sed -i "s/SERVICE_ACCOUNT_NAME/$ccSa/g" ../configs/config-connector.yaml
sed -i "s/PROJECT_ID/$projectId/g" ../configs/config-connector.yaml
kubectl apply -f ../configs/config-connector.yaml

# TODOs:
# - scope namespaced instead of cluster for Config Connector (to have proper sa scope)?
# - multi project id managementm not all in GKE's project
