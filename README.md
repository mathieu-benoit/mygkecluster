# mygkecluster

Based mostly on [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster).

```
export NODE_SA_NAME=gke-node-sa
gcloud iam service-accounts create $NODE_SA_NAME \
  --display-name "Node Service Account"
export NODE_SA_EMAIL=$(gcloud iam service-accounts list --format='value(email)' \
  --filter='displayName:Node Service Account')
  
export PROJECT=$(gcloud config get-value project)
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/monitoring.viewer
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/logging.logWriter
  
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$NODE_SA_EMAIL \
  --role roles/storage.objectViewer

gcloud container clusters create \
    --service-account $NODE_SA_EMAIL
    --release-channel rapid \
    --region \
    --disk-type pd-ssd \
    --machine-type n2d-standard-2 \
    --disk-size 256 \
    --image-type cos_containerd \
    --addons nodelocaldns,networkpolicy \
    --enable-shielded-nodes \
    --shielded-secure-boot \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-stackdriver-kubernetes
```
