output "network_name" {
  description = "Network name created by the networking module."
  value       = google_compute_network.module_vpc.name
}

output "subnet_names" {
  description = "Subnet names created by the networking module."
  value       = [for s in google_compute_subnetwork.module_subnets : s.name]
}
