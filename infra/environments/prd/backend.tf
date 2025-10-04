terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatebanditsprd"
    container_name       = "tfstate"
    key                  = "prd.terraform.tfstate"
  }
}
