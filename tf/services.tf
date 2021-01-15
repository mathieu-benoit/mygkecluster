# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
resource "google_project_service" "container" {
  project = google_project.project.id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = google_project.project.id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = google_project.project.id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containeranalysis" {
  project = google_project.project.id
  service = "containeranalysis.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containerscanning" {
  project = google_project.project.id
  service = "containerscanning.googleapis.com"

  disable_on_destroy = false
}