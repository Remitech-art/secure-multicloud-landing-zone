variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition     = length(var.azure_region) > 0
    error_message = "Azure region must not be empty."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "secure-multicloud"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 20 characters."
  }
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "VNET CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Must provide at least 2 public subnet CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "Must provide at least 2 private subnet CIDR blocks."
  }
}

variable "enable_storage_encryption" {
  description = "Enable encryption for storage accounts"
  type        = bool
  default     = true
}

variable "storage_retention_days" {
  description = "Retention period for storage account logs in days"
  type        = number
  default     = 90

  validation {
    condition     = var.storage_retention_days > 0
    error_message = "Retention days must be greater than 0."
  }
}

variable "enable_advanced_monitoring" {
  description = "Enable detailed monitoring with Application Insights"
  type        = bool
  default     = true
}

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Team       = "Platform-Engineering"
    CostCenter = "Engineering"
  }
}

variable "enable_bastion_host" {
  description = "Enable Azure Bastion host for secure RDP/SSH access"
  type        = bool
  default     = true
}

variable "enable_network_watcher" {
  description = "Enable Azure Network Watcher for network monitoring"
  type        = bool
  default     = true
}
