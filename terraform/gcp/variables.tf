variable "project_id" {
  description = "GCP project ID for the target environment."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "GCP region for resource deployment."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "org_id" {
  description = "GCP organization ID for Security Command Center and centralized IAM."
  type        = string
  default     = ""
}

variable "network_name" {
  description = "VPC network name."
  type        = string
  default     = "secure-multicloud-vpc"
}

variable "subnets" {
  description = "Map of subnet names to CIDR ranges." 
  type        = map(string)
  default = {
    public  = "10.10.0.0/24"
    private = "10.10.1.0/24"
    db      = "10.10.2.0/24"
  }
}

variable "bucket_name" {
  description = "Cloud Storage bucket name for platform artifacts and logs." 
  type        = string
  default     = "secure-multicloud-gcp-bucket"
}

variable "allowed_admin_cidrs" {
  description = "CIDR blocks allowed for administrative access such as SSH."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "allowed_public_cidrs" {
  description = "CIDR blocks allowed for public HTTP/HTTPS access."
  type        = list(string)
  default     = ["203.0.113.0/24"]
}

variable "enable_security_center" {
  description = "Enable GCP Security Command Center starter configuration."
  type        = bool
  default     = true
}
