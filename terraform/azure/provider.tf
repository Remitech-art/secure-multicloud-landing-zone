terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.46"
    }
  }

  # Uncomment to use Azure Storage backend for state management
  # backend "azurerm" {
  #   resource_group_name  = "your-resource-group"
  #   storage_account_name = "yourterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "azure/landing-zone/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }

  skip_provider_registration = false
}

provider "azuread" {
}

data "azurerm_client_config" "current" {}
