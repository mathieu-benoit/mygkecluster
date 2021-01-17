# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
resource "google_artifact_registry_repository" "container-images-repo" {
    provider = google-beta

    location = var.location
    repository_id = "container-images"
    format = "DOCKER"
}

resource "google_artifact_registry_repository" "helm-charts-repo" {
    provider = google-beta

    location = var.location
    repository_id = "helm-charts"
    format = "DOCKER"
}

resource "google_artifact_registry_repository" "rego-files-repo" {
    provider = google-beta

    location = var.location
    repository_id = "rego-files"
    format = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "gke-sa-pull-container-images" {
  provider = google-beta

  location = var.location
  repository = google_artifact_registry_repository.container-images-repo.name
  role   = "roles/artifactregistry.reader"
  member = format("serviceAccount:%s", google_service_account.gke.email)
}