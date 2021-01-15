terraform {
  required_providers {
    # https://github.com/hashicorp/terraform-provider-google
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }

  required_version = "~> 0.14"
}