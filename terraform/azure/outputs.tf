output "resource_group_id" {
  value       = azurerm_resource_group.main.id
  description = "The ID of the resource group"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "The name of the resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.main.id
  description = "The ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.main.name
  description = "The name of the virtual network"
}

output "vnet_cidr" {
  value       = azurerm_virtual_network.main.address_space
  description = "The address space of the virtual network"
}

output "public_subnet_ids" {
  value       = azurerm_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = azurerm_subnet.private[*].id
  description = "List of private subnet IDs"
}

output "bastion_subnet_id" {
  value       = var.enable_bastion_host ? azurerm_subnet.bastion[0].id : null
  description = "The ID of the bastion subnet"
}

output "public_nsg_id" {
  value       = azurerm_network_security_group.public.id
  description = "The ID of the public network security group"
}

output "private_nsg_id" {
  value       = azurerm_network_security_group.private.id
  description = "The ID of the private network security group"
}

output "key_vault_id" {
  value       = azurerm_key_vault.main.id
  description = "The ID of the Key Vault"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.main.vault_uri
  description = "The URI of the Key Vault"
}

output "storage_account_logs_id" {
  value       = azurerm_storage_account.logs.id
  description = "The ID of the logs storage account"
}

output "storage_account_logs_name" {
  value       = azurerm_storage_account.logs.name
  description = "The name of the logs storage account"
}

output "diagnostics_storage_account_id" {
  value       = azurerm_storage_account.diagnostics.id
  description = "The ID of the diagnostics storage account"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.main.id
  description = "The ID of the Log Analytics workspace"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.main.name
  description = "The name of the Log Analytics workspace"
}

output "application_insights_id" {
  value       = var.enable_advanced_monitoring ? azurerm_application_insights.main[0].id : null
  description = "The ID of Application Insights (if enabled)"
}

output "bastion_host_id" {
  value       = var.enable_bastion_host ? azurerm_bastion_host.main[0].id : null
  description = "The ID of the Azure Bastion host"
}

output "service_principal_client_id" {
  value       = azuread_service_principal.landing_zone.client_id
  description = "The client ID of the service principal"
}

output "service_principal_object_id" {
  value       = azuread_service_principal.landing_zone.object_id
  description = "The object ID of the service principal"
}

output "app_managed_identity_client_id" {
  value       = azurerm_user_assigned_identity.app.client_id
  description = "The client ID of the app managed identity"
}

output "app_managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.app.principal_id
  description = "The principal ID of the app managed identity"
}
