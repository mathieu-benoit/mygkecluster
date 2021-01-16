# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
// Enable required services on the project
resource "google_project_service" "service" {
    count   = length(var.project_services)
    service = element(var.project_services, count.index)

    // Do not disable the service on destroy. On destroy, we are going to
    // destroy the project, but we need the APIs available to destroy the
    // underlying resources.
    disable_on_destroy = false
}