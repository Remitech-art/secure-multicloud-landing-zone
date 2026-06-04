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
