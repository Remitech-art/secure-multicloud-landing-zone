variable "project_id" {
  description = "GCP project ID for security resources."
  type        = string
}

variable "org_id" {
  description = "GCP organization ID for Security Command Center."
  type        = string
  default     = ""
}

variable "enable_security_center" {
  description = "Enable Security Command Center configuration."
  type        = bool
  default     = true
}
