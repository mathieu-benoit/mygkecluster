# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "cluster" {
    provider = google-beta
    
    name                        = "gke-name-fixme"
    location                    = var.location
    default_max_pods_per_node   = 30
    enable_binary_authorization = true
    enable_shielded_nodes       = true
    networking_mode             = "VPC_NATIVE"
    remove_default_node_pool    = true
    initial_node_count          = 1

    release_channel {
        channel = "RAPID"
    }

    addons_config {
        http_load_balancing {
            disabled = false
        }

        network_policy_config {
            disabled = false
        }

        dns_cache_config {
            enabled = true
        }

        config_connector_config {
            enabled = true
        }
    }

    network_policy {
        enabled = true
    }

    workload_identity_config {
        identity_namespace = format("%s.svc.id.goog", var.project_id)
    }

    private_cluster_config {
        enable_private_endpoint = "false" # TODO
        enable_private_nodes    = "false" # TODO
    }

    vertical_pod_autoscaling {
        enabled = false
    }

    depends_on = [
        google_project_service.service
    ]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
resource "google_container_node_pool" "default-nodepool" {
    name              = "default-pool"
    location          = var.location
    cluster           = google_container_cluster.cluster.name
    node_count        = var.gke_num_nodes
    max_pods_per_node = 30

    node_config {
        service_account = google_service_account.gke.email
        machine_type    = var.gke_machine_type
        disk_type       = "pd-ssd"
        disk_size_gb    = 256
        image_type      = "COS_CONTAINERD"

        shielded_instance_config {
            enable_secure_boot = true
        }

        workload_metadata_config {
            node_metadata = "GKE_METADATA"
        }
    }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/binary_authorization_policy
resource "google_binary_authorization_policy" "policy" {
    admission_whitelist_patterns {
        name_pattern = "$region-docker.pkg.dev/$projectId/$containerRegistryName/*"
    }

    default_admission_rule {
        evaluation_mode  = "ALWAYS_DENY"
        enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    }

    global_policy_evaluation_mode = "ENABLE"
}