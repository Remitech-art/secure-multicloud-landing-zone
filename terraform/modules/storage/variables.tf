variable "project_id" {
  description = "GCP project ID for storage resources."
  type        = string
}

variable "region" {
  description = "GCP region used for bucket location."
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "Cloud Storage bucket name."
  type        = string
}

variable "service_account_email" {
  description = "Service account email that should be granted storage access."
  type        = string
}
