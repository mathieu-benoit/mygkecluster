# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "gke" {
    account_id   = "fixme-node-sa"
    display_name = "GKE Security Service Account"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam
resource "google_project_iam_member" "service-account" {
    count   = length(var.gke_sa_roles)
    role    = element(var.gke_sa_roles, count.index)
    member  = format("serviceAccount:%s", google_service_account.gke.email)
}