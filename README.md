# mygkecluster

Based mostly on [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster) and [GKE's Security overview](https://cloud.google.com/kubernetes-engine/docs/concepts/security-overview).

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

Here are the exhaustive list of the security best practices with your GKE clusters you should look at:
- [Use least privilege Google service accounts](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)
- [Creating a Private cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [Adding authorized networks for cluster master access](https://cloud.google.com/kubernetes-engine/docs/how-to/authorized-networks)
- [Nodes auto-upgrades](https://cloud.google.com/kubernetes-engine/docs/concepts/node-auto-upgrades)
- [Container-Optimized OS](https://cloud.google.com/container-optimized-os/docs/concepts/features-and-benefits)
- [RBAC](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control)
- [Enable network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)
- [Enable Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Enable Binary Authorization with GCR](https://cloud.google.com/binary-authorization/docs/overview)
- [Enable Vulnerability scanning on GCR](https://cloud.google.com/container-registry/docs/vulnerability-scanning)

Here are actions you may want to do once your GKE clusters are deployed to help solidify your security posture:
- [Credential rotation](https://cloud.google.com/kubernetes-engine/docs/how-to/credential-rotation)
- [Configure Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Harden workload isolation with GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods)
