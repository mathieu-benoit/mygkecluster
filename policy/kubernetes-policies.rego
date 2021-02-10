package kubernetes.validating.images

deny[msg] {
	input.kind == "Deployment"
	image := input.request.object.spec.containers[i].image
	not startswith(image, "hooli.com/")
	msg := sprintf("Image '%v' comes from untrusted registry", [image])
}

deny[msg] {
  some i
  input.kind == "Deployment"
  not input.spec.selector.matchLabels.app
  msg := "Containers must provide app label for pod selectors"
}
