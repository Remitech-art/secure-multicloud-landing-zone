terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  backend_resource_labels = merge(var.common_labels, {
    project = var.project_name
  })
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}

resource "google_storage_bucket" "terraform_state" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  retention_policy {
    retention_period = 15552000
  }

  labels = local.backend_resource_labels
}

output "backend_bucket_name" {
  value       = google_storage_bucket.terraform_state.name
  description = "The GCS bucket name used for Terraform remote state."
}

output "backend_bucket_location" {
  value       = google_storage_bucket.terraform_state.location
  description = "The GCS bucket region used for Terraform remote state."
}
