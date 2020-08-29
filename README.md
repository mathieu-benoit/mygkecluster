# mygkecluster

Based mostly on [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster).

```
projectId=FIXME
region=us-east4

# Setup Project
projectName=FIXME
folderId=FIXME
billingAccountId=FIXME
gcloud projects create $projectId \
    --folder $folderId \
    --name $projectName
gcloud config set project $projectId
gcloud beta billing accounts list

gcloud beta billing projects link $projectId \
    --billing-account $billingAccountId

# Least Privileges Service Account for default node pool
gcloud services enable cloudresourcemanager.googleapis.com
saName=FIXME
saId=$saName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $saName \
  --display-name=$saName
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/logging.logWriter
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/monitoring.viewer
  
# Setup GCR
gcloud services enable containerregistry.googleapis.com
gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/storage.objectViewer

# Create GKE cluster
randomSuffix=$(shuf -i 100-999 -n 1)
clusterName=FIXME-$randomSuffix
gcloud container clusters create $clusterName \
    --service-account $saId \
    --release-channel rapid \
    --region $region \
    --disk-type pd-ssd \
    --machine-type n2d-standard-2 \
    --disk-size 256 \
    --image-type cos_containerd \
    --addons NodeLocalDNS,NetworkPolicy,HttpLoadBalancing \
    --enable-shielded-nodes \
    --shielded-secure-boot \
    --enable-ip-alias \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-stackdriver-kubernetes
```
