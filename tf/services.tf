resource "google_project_service" "container" {
  project = var.default_project
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.default_project
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.default_project
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containeranalysis" {
  project = var.default_project
  service = "containeranalysis.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containerscanning" {
  project = var.default_project
  service = "containerscanning.googleapis.com"

  disable_on_destroy = false
}