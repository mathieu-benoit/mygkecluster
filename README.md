# mygkecluster

Based mostly on [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster) and [GKE's Security overview](https://cloud.google.com/kubernetes-engine/docs/concepts/security-overview).

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/mathieu-benoit/mygkecluster&cloudshell_tutorial=README.md)

## Prerequisities

- Install `gcloud`
- Install `terraform`
- Install `helm`
- Install `kubectl`
- Install `docker`

Get latest Config Sync Operator:
```
cd components
version=1.6.0
gsutil cp gs://config-management-release/released/$version/config-sync-operator.yaml config-sync-operator.yaml
```

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
```

## By `terraform`

```
cd tf
terraform init
terraform plan -var project_id=$projectId
terraform apply -auto-approve
```

## By `bash` script

```
cd cli
./run.sh
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
- [Security in KubeCon Europe 2020](https://blog.aquasec.com/kubecon-2020-europe)
