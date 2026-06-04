############################################
# Storage Account for Logs and Data
############################################

resource "azurerm_storage_account" "logs" {
  name                     = replace("${var.project_name}logs${local.location_short}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  shared_access_key_enabled  = false

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-logs-storage"
    }
  )
}

############################################
# Storage Account Encryption
############################################

resource "azurerm_storage_account_customer_managed_key" "logs" {
  count              = var.enable_storage_encryption ? 1 : 0
  storage_account_id = azurerm_storage_account.logs.id
  key_vault_id       = azurerm_key_vault.main.id
  key_name           = azurerm_key_vault_key.storage.name
}

############################################
# Key Vault Keys for Encryption
############################################

resource "azurerm_key_vault_key" "storage" {
  name         = "${var.project_name}-storage-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  tags = local.common_tags
}

############################################
# Storage Account Blob Container
############################################

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.logs.name
  container_access_type = "private"
}

############################################
# Blob Storage for Diagnostic Logs
############################################

resource "azurerm_storage_account" "diagnostics" {
  name                     = replace("${var.project_name}diag${local.location_short}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-diagnostics-storage"
    }
  )
}

resource "azurerm_storage_container" "diagnostics" {
  name                  = "diagnostics"
  storage_account_name  = azurerm_storage_account.diagnostics.name
  container_access_type = "private"
}

############################################
# Storage Account Network Rules
############################################

resource "azurerm_storage_account_network_rules" "logs" {
  storage_account_id = azurerm_storage_account.logs.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = concat(
    azurerm_subnet.public[*].id,
    azurerm_subnet.private[*].id
  )
}

resource "azurerm_storage_account_network_rules" "diagnostics" {
  storage_account_id = azurerm_storage_account.diagnostics.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = concat(
    azurerm_subnet.public[*].id,
    azurerm_subnet.private[*].id
  )
}
