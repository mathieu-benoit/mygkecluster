terraform {
    required_providers {
        # https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
        google = {
          source  = "hashicorp/google"
          version = "4.4.0"
        }

        google-beta = {
          source  = "hashicorp/google-beta"
          version = "4.4.0"
        }
    }

    required_version = "~> 0.14"
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

data "google_project" "project" {
  project_id = var.project_id
}