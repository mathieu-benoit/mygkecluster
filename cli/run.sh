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
gcloud services enable containerfilesystem.googleapis.com
# Delete the default compute engine service account if you don't have have the Org policy iam.automaticIamGrantsForDefaultServiceAccounts in place
projectNumber=$(gcloud projects describe $projectId --format='get(projectNumber)')
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
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM \
    --max-pods-per-node 30 \
    --default-max-pods-per-node 30 \
    --services-ipv4-cidr '/25' \
    --cluster-ipv4-cidr '/20' \
    --enable-vertical-pod-autoscaling \
    --enable-master-authorized-networks \
    --master-authorized-networks $myIpAddress/32 \
    --enable-image-streaming \
    --labels mesh_id=proj-${PROJECT_NUMBER}

# Update to latest version of the current channel
newVersion=FIXME
gcloud container clusters upgrade $clusterName --master \
    --zone $zone \
    --cluster-version $newVersion \
    --quiet
gcloud container clusters upgrade $clusterName \
    --zone $zone \
    --quiet

# Enable Anthos
gcloud services enable anthos.googleapis.com
gcloud container hub memberships register $clusterName \
    --gke-cluster $zone/$clusterName \
    --enable-workload-identity

# ASM
gcloud services enable mesh.googleapis.com
gcloud container hub mesh enable
gcloud alpha container hub mesh update \
     --control-plane automatic \
     --membership $clusterName

# Cloud Armor for the ASM Ingress Gateway
securityPolicyName=$clusterName-asm-ingressgateway # Name hard-coded there: https://github.com/mathieu-benoit/my-kubernetes-deployments/tree/main/namespaces/asm-ingress/backendconfig.yaml
gcloud compute security-policies create $securityPolicyName \
    --description "Block XSS attacks"
gcloud compute security-policies rules create 1000 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('xss-stable')" \
    --action "deny-403" \
    --description "XSS attack filtering"
gcloud compute security-policies rules create 2000 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('sqli-stable', ['owasp-crs-v030001-id942251-sqli', 'owasp-crs-v030001-id942420-sqli', 'owasp-crs-v030001-id942431-sqli', 'owasp-crs-v030001-id942460-sqli', 'owasp-crs-v030001-id942421-sqli', 'owasp-crs-v030001-id942432-sqli'])" \
    --action "deny-403" \
    --description "SQL injection levels 1 and 2"
gcloud compute security-policies rules create 3000 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('lfi-stable')" \
    --action "deny-403" \
    --description "Local file inclusion"
gcloud compute security-policies rules create 4000 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('rfi-stable')" \
    --action "deny-403" \
    --description "Remote file inclusion"
gcloud compute security-policies rules create 12345 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('cve-canary')" \
    --action "deny-403" \
    --description "CVE-2021-44228 and CVE-2021-45046"
gcloud compute security-policies update $securityPolicyName \
    --enable-layer7-ddos-defense
gcloud compute security-policies update $securityPolicyName \
    --log-level=VERBOSE
sslPolicyName=$securityPolicyName # Name hard-coded there: https://github.com/mathieu-benoit/my-kubernetes-deployments/tree/main/namespaces/asm-ingress/frontendconfig.yaml
gcloud compute ssl-policies create $sslPolicyName \
    --profile COMPATIBLE  \
    --min-tls-version 1.0

# Public IP for the ASM Ingress Gateway
staticIpName=$clusterName-asm-ingressgateway # Name hard-coded there: https://github.com/mathieu-benoit/my-kubernetes-deployments/tree/main/namespaces/asm-ingress/ingress.yaml
gcloud compute addresses create $staticIpName \
    --global
gcloud compute addresses describe $staticIpName \
    --global \
    --format "value(address)"
# Grab that IP address to setup the DNS entries.

# Provision infra specifically per apps (asm-ingress, myblog, onlineboutique, bankofanthos) before doing the config sync section below

# Config Sync
gcloud beta container hub config-management enable
gcloud beta container hub config-management apply \
  --membership $clusterName \
  --version 1.10 \
  --config ../configs/configsync-config.yaml
