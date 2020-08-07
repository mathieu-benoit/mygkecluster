# mygkecluster

```
gcloud container clusters create \
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
