# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
resource "google_artifact_registry_repository" "container-images-repo" {
  provider = google-beta

  location = var.location
  repository_id = "container-images"
  format = "docker"
}

resource "google_artifact_registry_repository" "helm-charts-repo" {
  provider = google-beta

  location = var.location
  repository_id = "helm-charts"
  format = "docker"
}

resource "google_artifact_registry_repository" "rego-files-repo" {
  provider = google-beta

  location = var.location
  repository_id = "rego-files"
  format = "docker"
}