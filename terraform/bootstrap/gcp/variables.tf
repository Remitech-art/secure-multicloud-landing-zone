variable "project_id" {
  description = "GCP project ID for bootstrap backend resources."
  type        = string
}

variable "project_name" {
  description = "Project name for backend resource naming."
  type        = string
  default     = "secure-multicloud"
}

variable "region" {
  description = "GCP region for backend state bucket."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone used by the provider."
  type        = string
  default     = "us-central1-a"
}

variable "bucket_name" {
  description = "Name of the GCS bucket used for Terraform remote state."
  type        = string
  default     = "secure-multicloud-terraform-state"
}

variable "common_labels" {
  description = "Common labels for backend resources."
  type        = map(string)
  default = {
    team       = "platform-engineering"
    cost_center = "engineering"
  }
}
