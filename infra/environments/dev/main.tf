terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # subscription_id is read from ARM_SUBSCRIPTION_ID environment variable
}

locals {
  common_tags = {
    Project     = "research-bandits"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-dev"
  location = var.location

  tags = local.common_tags
}
