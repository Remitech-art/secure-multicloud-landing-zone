terraform {
  backend "azurerm" {
    resource_group_name  = "secure-multicloud-tfstate-rg"
    storage_account_name = "securemulticloudtfstate"
    container_name       = "tfstate"
    key                  = "azure/landing-zone/terraform.tfstate"
  }
}
