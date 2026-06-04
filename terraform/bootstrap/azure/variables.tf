variable "azure_region" {
  description = "Azure region for bootstrap backend resources."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name for backend resource naming."
  type        = string
  default     = "secure-multicloud"
}

variable "resource_group_name" {
  description = "Azure resource group name for Terraform backend resources."
  type        = string
  default     = "secure-multicloud-tfstate-rg"
}

variable "storage_account_name" {
  description = "Azure storage account name for Terraform state."
  type        = string
  default     = "securemulticloudtfstate"
}

variable "container_name" {
  description = "Azure blob container name for Terraform state."
  type        = string
  default     = "tfstate"
}

variable "common_tags" {
  description = "Common tags for backend resources."
  type        = map(string)
  default = {
    Team       = "Platform-Engineering"
    CostCenter = "Engineering"
  }
}
