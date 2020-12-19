# mygkecluster

Based mostly on [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster) and [GKE's Security overview](https://cloud.google.com/kubernetes-engine/docs/concepts/security-overview).

```
projectName=mygke
randomSuffix=$(shuf -i 100-999 -n 1)
projectId=$projectName-$randomSuffix
region=us-east4
zone=us-east4-a
clusterName=$projectName

## Setup Project

folderId=FIXME
gcloud projects create $projectId \
    --folder $folderId \
    --name $projectName
gcloud config set project $projectId
# Get the billingAccountId from `gcloud beta billing accounts list`
billingAccountId=FIXME
gcloud beta billing projects link $projectId \
    --billing-account $billingAccountId
projectNumber="$(gcloud projects describe $projectId --format='get(projectNumber)')"

# Protect against project deletion
gcloud alpha resource-manager liens create \
    --restrictions=resourcemanager.projects.delete \
    --reason="Avoid deletion."

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
cat > policy.yaml << EOF
admissionWhitelistPatterns:
- namePattern: $region-docker.pkg.dev/$projectId/$containerRegistryName/*
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
globalPolicyEvaluationMode: ENABLE
name: projects/$projectId/policy
EOF
gcloud container binauthz policy import policy.yaml

## Create GKE cluster
gcloud services enable container.googleapis.com
# Delete the default compute engine service account if you don't have have the Org policy iam.automaticIamGrantsForDefaultServiceAccounts in place
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
    --zone $zone
    
## Add a label to kube-system namespace, as per https://alwaysupalwayson.com/calico/
kubectl label ns kube-system name=kube-system
```

Here are the exhaustive list of the security best practices with your GKE clusters you should look at:
- [X] [Use least privilege Google service accounts](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)
- [ ] [Creating a Private cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [ ] [Adding authorized networks for cluster master access](https://cloud.google.com/kubernetes-engine/docs/how-to/authorized-networks)
- [X] [Nodes auto-upgrades](https://cloud.google.com/kubernetes-engine/docs/concepts/node-auto-upgrades)
- [X] [Container-Optimized OS](https://cloud.google.com/container-optimized-os/docs/concepts/features-and-benefits)
- [X] [Using Shielded GKE Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes)
- [ ] [RBAC](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control)
- [X] [Enable network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)
- [X] [Enable Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [ ] [Enable Binary Authorization](https://cloud.google.com/binary-authorization/docs/overview)
- [X] [Enable Vulnerability scanning on container registry](https://cloud.google.com/container-registry/docs/vulnerability-scanning)
- [ ] [Application-layer Secrets Encryption](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets)
- [ ] [(alpha) Using network policy logging with Dataplane V2/eBPF](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging)
- [X] [(beta) Confidential VMs](https://cloud.google.com/blog/products/identity-security/introducing-google-cloud-confidential-computing-with-confidential-vms)

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
