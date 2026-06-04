locals {
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  )

  resource_group_name = "${var.project_name}-${var.environment}-rg"
  location_short      = substr(var.azure_region, 0, 4)
}
