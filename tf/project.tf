# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project
resource "google_project" "project" {
  name       = "My Project"
  project_id = "your-project-id"
  folder_id  = var.folder_id
}