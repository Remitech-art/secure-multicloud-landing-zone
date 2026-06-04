variable "project_id" {
  description = "GCP project ID for monitoring resources."
  type        = string
}

variable "bucket_name" {
  description = "Cloud Storage bucket for logging sinks and retention."
  type        = string
}
