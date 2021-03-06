package main

deny[msg] {
  some i
  input.kind == "Deployment"
  image := input.spec.template.spec.containers[i].image
  not startswith(image, "us-east4-docker.pkg.dev/mygke-955/containers/")
  msg := sprintf("Image '%v' comes from untrusted registry", [image])
}

deny[msg] {
  input.kind == "Deployment"
  not input.spec.selector.matchLabels.app
  msg := "Containers must provide app label for pod selectors"
}
