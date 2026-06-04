############################################
# Azure Bastion Host
############################################

resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = "${var.project_name}-bastion-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = "${var.project_name}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = local.common_tags
}

############################################
# Key Vault for Secrets Management
############################################

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${local.location_short}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  enabled_for_template_deployment = true
  enable_rbac_authorization   = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-key-vault"
    }
  )
}

############################################
# Azure AD Application (for RBAC)
############################################

resource "azuread_application" "landing_zone" {
  display_name = "${var.project_name}-app"

  owners = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "landing_zone" {
  client_id = azuread_application.landing_zone.client_id

  owners = [data.azurerm_client_config.current.object_id]
}

############################################
# Role Assignments
############################################

resource "azurerm_role_assignment" "service_principal_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.landing_zone.object_id
}

############################################
# Managed Identity for Applications
############################################

resource "azurerm_user_assigned_identity" "app" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${var.project_name}-app-identity"

  tags = local.common_tags
}

resource "azurerm_role_assignment" "app_managed_identity" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
