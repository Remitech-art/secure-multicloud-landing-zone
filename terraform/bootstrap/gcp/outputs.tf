output "backend_bucket_name" {
  value       = google_storage_bucket.terraform_state.name
  description = "The GCS bucket name used for Terraform remote state."
}

output "backend_bucket_location" {
  value       = google_storage_bucket.terraform_state.location
  description = "The GCS bucket location used for Terraform remote state."
}
