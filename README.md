# mygkecluster

Based mostly on [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster) and [GKE's Security overview](https://cloud.google.com/kubernetes-engine/docs/concepts/security-overview).

```
projectId=FIXME
region=us-east4
randomSuffix=$(shuf -i 100-999 -n 1)
clusterName=FIXME-$randomSuffix

## Setup Project
projectName=FIXME
folderId=FIXME
# Get the billingAccountId from `gcloud beta billing accounts list`
billingAccountId=FIXME
gcloud projects create $projectId \
    --folder $folderId \
    --name $projectName
gcloud config set project $projectId
gcloud beta billing projects link $projectId \
    --billing-account $billingAccountId
projectNumber="$(gcloud projects describe $projectId --format='get(projectNumber)')"

## Least Privilege Service Account for default node pool
gcloud services enable cloudresourcemanager.googleapis.com
saId=$clusterName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $clusterName \
  --display-name=$clusterName
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/logging.logWriter
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/monitoring.viewer
  
## Setup GCR
gcloud services enable containerregistry.googleapis.com
gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/storage.objectViewer

## Create GKE cluster
gcloud services enable container.googleapis.com
# Delete the default compute engine service account if you don't have have the Org policy iam.automaticIamGrantsForDefaultServiceAccounts in place
gcloud iam service-accounts delete $projectNumber-compute@developer.gserviceaccount.com --quiet
gcloud container clusters create $clusterName \
    --service-account $saId \
    --workload-pool=$projectId.svc.id.goog \
    --release-channel rapid \
    --region $region \
    --disk-type pd-ssd \
    --machine-type n2d-standard-2 \
    --disk-size 256 \
    --image-type cos_containerd \
    --enable-network-policy \
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
    --cluster-ipv4-cidr '/20'

## Get GKE cluster kubeconfig
gcloud container clusters get-credentials $clusterName \
    --region $region
```

Here are the exhaustive list of the security best practices with your GKE clusters you should look at:
- [Use least privilege Google service accounts](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)
- [Creating a Private cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [Adding authorized networks for cluster master access](https://cloud.google.com/kubernetes-engine/docs/how-to/authorized-networks)
- [Nodes auto-upgrades](https://cloud.google.com/kubernetes-engine/docs/concepts/node-auto-upgrades)
- [Container-Optimized OS](https://cloud.google.com/container-optimized-os/docs/concepts/features-and-benefits)
- [Using Shielded GKE Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes)
- [RBAC](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control)
- [Enable network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)
- [Enable Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Enable Binary Authorization with GCR](https://cloud.google.com/binary-authorization/docs/overview)
- [Enable Vulnerability scanning on GCR](https://cloud.google.com/container-registry/docs/vulnerability-scanning)
- [Application-layer Secrets Encryption](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets)

Alpha/Beta considerations:
- [Using network policy logging with Dataplane V2/eBPF](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging)
- [Confidential VMs](https://cloud.google.com/blog/products/identity-security/introducing-google-cloud-confidential-computing-with-confidential-vms)

Here are actions you may want to do once your GKE clusters are deployed to help solidify your security posture:
- [Having a GitOps approach to deploy your app in GKE](https://www.weave.works/blog/what-is-gitops-really) or for example [Anthos Config Management](https://cloud.google.com/anthos/config-management)
- [Observing your GKE clusters with Google Cloud Ops Suite](https://cloud.google.com/stackdriver/docs/solutions/gke/observing)
- [Control plane IP rotation](https://cloud.google.com/kubernetes-engine/docs/how-to/ip-rotation)
- [Credential rotation](https://cloud.google.com/kubernetes-engine/docs/how-to/credential-rotation)
- [Configure Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Harden workload isolation with GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods)
- + Cloud Armor (DDOS + WAF) - FIXME
- + Service Mesh - FIXME

Complementary resources:
- [The Unofficial Google Kubernetes Engine (GKE) Security Guide](https://gkesecurity.guide/)
- [Best practices for enterprise multi-tenancy with GKE](https://cloud.google.com/kubernetes-engine/docs/best-practices/enterprise-multitenancy)
- [Security blueprint: PCI on GKE](https://cloud.google.com/architecture/blueprints/gke-pci-dss-blueprint)
