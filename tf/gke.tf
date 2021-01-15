# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "cluster" {
  name     = "gke-name-fixme"
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
resource "google_container_node_pool" "default-nodepool" {
  name       = "default-pool"
  location   = var.location
  cluster    = google_container_cluster.cluster.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    machine_type = var.gke_machine_type
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}