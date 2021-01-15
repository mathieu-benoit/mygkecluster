# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
resource "google_project_service" "container" {
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containeranalysis" {
  service = "containeranalysis.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containerscanning" {
  service = "containerscanning.googleapis.com"

  disable_on_destroy = false
}