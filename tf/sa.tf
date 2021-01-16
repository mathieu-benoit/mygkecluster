resource "google_service_account" "gke" {
    account_id   = "fixme-node-sa"
    display_name = "GKE Security Service Account"
}