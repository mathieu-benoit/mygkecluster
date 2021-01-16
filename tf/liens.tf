# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/resource_manager_lien
/*resource "google_resource_manager_lien" "project-lien" {
    parent       = "projects/${google_project.project.number}"
    restrictions = ["resourcemanager.projects.delete"]
    origin       = "machine-readable-explanation"
    reason       = "Avoid project deletion."
}*/