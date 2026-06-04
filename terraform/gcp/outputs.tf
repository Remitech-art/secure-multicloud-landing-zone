output "gcp_vpc_name" {
  description = "The name of the created GCP VPC."
  value       = google_compute_network.vpc.name
}

output "gcp_subnet_names" {
  description = "The names of created GCP subnets."
  value       = [for s in google_compute_subnetwork.subnets : s.name]
}

output "gcp_storage_bucket" {
  description = "The name of the created Cloud Storage bucket."
  value       = google_storage_bucket.artifacts.name
}

output "platform_service_account" {
  description = "Email of the platform service account."
  value       = google_service_account.platform.email
}
