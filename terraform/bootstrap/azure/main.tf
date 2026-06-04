terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  backend_resource_tags = merge(var.common_tags, { Name = "${var.project_name}-terraform-backend" })
}

resource "azurerm_resource_group" "backend" {
  name     = var.resource_group_name
  location = var.azure_region
  tags     = local.backend_resource_tags
}

resource "azurerm_storage_account" "backend" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  allow_blob_public_access = false
  min_tls_version          = "TLS1_2"
  is_hns_enabled           = false
  enable_https_traffic_only = true

  tags = local.backend_resource_tags
}

resource "azurerm_storage_container" "backend" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.backend.name
  container_access_type = "private"
}

output "backend_resource_group_name" {
  value       = azurerm_resource_group.backend.name
  description = "The resource group used for Azure Terraform backend storage."
}

output "storage_account_name" {
  value       = azurerm_storage_account.backend.name
  description = "The Azure Storage account name used for Terraform state."
}

output "container_name" {
  value       = azurerm_storage_container.backend.name
  description = "The blob container used for Azure Terraform state."
}
