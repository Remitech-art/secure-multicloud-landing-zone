variable "project_id" {
  description = "GCP project ID for networking resources."
  type        = string
}

variable "region" {
  description = "GCP region for subnets."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "subnets" {
  description = "Map of subnet names and CIDR ranges." 
  type        = map(string)
}
