############################################
# Resource Group
############################################

resource "azurerm_resource_group" "main" {
  name       = local.resource_group_name
  location   = var.azure_region
  tags       = local.common_tags
}

############################################
# Virtual Network
############################################

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vnet"
    }
  )
}

############################################
# Public Subnets
############################################

resource "azurerm_subnet" "public" {
  count                = length(var.public_subnet_cidrs)
  name                 = "${var.project_name}-public-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidrs[count.index]]

  private_endpoint_network_policies_enabled = true

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

############################################
# Private Subnets
############################################

resource "azurerm_subnet" "private" {
  count                = length(var.private_subnet_cidrs)
  name                 = "${var.project_name}-private-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_cidrs[count.index]]

  private_endpoint_network_policies_enabled = true
}

############################################
# Bastion Subnet (for Azure Bastion)
############################################

resource "azurerm_subnet" "bastion" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes    = ["10.1.100.0/24"]
}

############################################
# Network Security Groups - Public
############################################

resource "azurerm_network_security_group" "public" {
  name                = "${var.project_name}-public-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-nsg"
    }
  )
}

resource "azurerm_network_security_rule" "public_inbound_http" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_inbound_https" {
  name                        = "AllowHTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_outbound" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.public.name
}

############################################
# Network Security Groups - Private
############################################

resource "azurerm_network_security_group" "private" {
  name                = "${var.project_name}-private-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-private-nsg"
    }
  )
}

resource "azurerm_network_security_rule" "private_inbound_vnet" {
  name                        = "AllowVNetInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.private.name
}

resource "azurerm_network_security_rule" "private_outbound" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.private.name
}

############################################
# NSG Associations
############################################

resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = length(azurerm_subnet.public)
  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = length(azurerm_subnet.private)
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

############################################
# Network Watcher
############################################

resource "azurerm_network_watcher" "main" {
  count               = var.enable_network_watcher ? 1 : 0
  name                = "${var.project_name}-network-watcher"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

############################################
# Network Watcher Flow Logs
############################################

resource "azurerm_storage_account" "network_watcher_logs" {
  count                    = var.enable_network_watcher ? 1 : 0
  name                     = replace("${var.project_name}nwlogs${local.location_short}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-network-watcher-logs"
    }
  )
}

resource "azurerm_network_watcher_flow_log" "public" {
  count                    = var.enable_network_watcher ? length(azurerm_network_security_group.public) : 0
  network_watcher_name     = azurerm_network_watcher.main[0].name
  resource_group_name      = azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.public.id
  storage_account_id       = azurerm_storage_account.network_watcher_logs[0].id
  enabled                  = true
  version                  = 2

  retention_policy {
    enabled = true
    days    = var.storage_retention_days
  }
}

resource "azurerm_network_watcher_flow_log" "private" {
  count                    = var.enable_network_watcher ? length(azurerm_network_security_group.private) : 0
  network_watcher_name     = azurerm_network_watcher.main[0].name
  resource_group_name      = azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.private.id
  storage_account_id       = azurerm_storage_account.network_watcher_logs[0].id
  enabled                  = true
  version                  = 2

  retention_policy {
    enabled = true
    days    = var.storage_retention_days
  }
}
