variable "project_id" {
    description = "id of the project"
}

variable "location" {
    default     = "us-east4-a"
    description = "location (zone or region) of the resources"
}

variable "gke_num_nodes" {
    default     = 3
    description = "number of gke nodes"
}

variable "gke_machine_type" {
    default     = "n2d-standard-2"
    description = "machine type of gke nodes"
}

variable "project_services" {
    type = list

    default = [
        "cloudresourcemanager.googleapis.com",
        "container.googleapis.com",
        "artifactregistry.googleapis.com",
        "containeranalysis.googleapis.com",
        "containerscanning.googleapis.com",
        "binaryauthorization.googleapis.com"
    ]
    description = "The GCP APIs that should be enabled in this project."
}