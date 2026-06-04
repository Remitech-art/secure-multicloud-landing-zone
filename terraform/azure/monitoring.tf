############################################
# Log Analytics Workspace
############################################

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-log-analytics"
    }
  )
}

############################################
# Application Insights
############################################

resource "azurerm_application_insights" "main" {
  count               = var.enable_advanced_monitoring ? 1 : 0
  name                = "${var.project_name}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-application-insights"
    }
  )
}

############################################
# Monitor Action Group
############################################

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-action-group"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "SmartAlert"

  tags = local.common_tags
}

############################################
# Monitor Diagnostic Setting for Key Vault
############################################

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name               = "${var.project_name}-kv-diagnostics"
  target_resource_id = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}

############################################
# Monitor Diagnostic Setting for Storage
############################################

resource "azurerm_monitor_diagnostic_setting" "storage_logs" {
  name               = "${var.project_name}-storage-logs-diagnostics"
  target_resource_id = azurerm_storage_account.logs.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }
}

############################################
# Monitor Metric Alert
############################################

resource "azurerm_monitor_metric_alert" "high_latency" {
  count               = var.enable_advanced_monitoring ? 1 : 0
  name                = "${var.project_name}-high-latency-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main[0].id]
  description         = "Alert when response time is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

############################################
# Log Analytics Query Packs (Custom Alerts)
############################################

resource "azurerm_log_analytics_query_pack" "main" {
  name                = "${var.project_name}-queries"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = local.common_tags
}

resource "azurerm_log_analytics_query_pack_query" "vnet_traffic" {
  query_pack_id = azurerm_log_analytics_query_pack.main.id
  body          = "AzureDiagnostics | where Category == 'NetworkSecurityGroupFlowLogEvent' | summarize count() by Action"
  display_name  = "VNet Traffic Summary"
}

############################################
# Azure Defender Settings
############################################

resource "azurerm_security_center_setting" "threat_detection" {
  setting_name       = "MCAS"
  enabled            = true
}

############################################
# Audit Policy - VNET
############################################

resource "azurerm_monitor_diagnostic_setting" "vnet_audit" {
  name               = "${var.project_name}-vnet-audit"
  target_resource_id = azurerm_virtual_network.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
  }
}
