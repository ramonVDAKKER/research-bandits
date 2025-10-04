terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
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

# Look up existing GitHub Actions service principal
data "azuread_service_principal" "github_actions" {
  display_name = var.github_actions_sp_name
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-dev"
  location = var.location

  tags = local.common_tags
}

# Log Analytics Workspace (shared across all services)
module "log_analytics" {
  source = "../../modules/log_analytics"

  name                = "law-${var.project_name}-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = var.log_analytics_retention_days

  tags = local.common_tags
}

# Container Apps Environment (public with IP restrictions applied per app)
module "container_apps_environment" {
  source = "../../modules/container_apps_environment"

  name                       = "cae-${var.project_name}-dev"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.common_tags
}

# App Service Plan (Free tier, Linux containers)
module "app_service_plan" {
  source = "../../modules/app_service_plan"

  name                = "asp-${var.project_name}-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.app_service_plan_sku

  tags = local.common_tags
}

# Azure Container Registry (Basic SKU with RBAC)
module "container_registry" {
  source = "../../modules/container_registry"

  name                                 = var.acr_name
  location                             = var.location
  resource_group_name                  = azurerm_resource_group.main.name
  sku                                  = var.acr_sku
  acr_allowed_ips                      = var.acr_allowed_ips
  container_apps_identity_principal_id = module.container_apps_environment.managed_identity_principal_id
  app_service_identity_principal_id    = module.app_service_plan.managed_identity_principal_id
  github_actions_sp_object_id          = data.azuread_service_principal.github_actions.object_id

  tags = local.common_tags
}

# Backend Container App Job (on-demand execution)
module "backend_job" {
  source = "../../modules/container_app_job"

  name                         = "caj-${var.project_name}-backend-dev"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.container_apps_environment.id
  container_image              = "${module.container_registry.login_server}/research-bandits-backend:latest"
  acr_login_server             = module.container_registry.login_server
  managed_identity_id          = module.container_apps_environment.managed_identity_id

  cpu                        = "0.5"
  memory                     = "1.0Gi"
  replica_timeout_in_seconds = 3600
  replica_retry_limit        = 1
  parallelism                = 1
  replica_completion_count   = 1

  environment_variables = var.backend_env_vars

  tags = local.common_tags
}

# Frontend App Service (Streamlit with Azure AD auth)
module "frontend_app" {
  source = "../../modules/app_service"

  name                = "app-${var.project_name}-frontend-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = module.app_service_plan.id
  container_image     = "research-bandits-frontend:latest"
  acr_login_server    = module.container_registry.login_server
  managed_identity_id = module.app_service_plan.managed_identity_id

  aad_client_id         = var.aad_client_id
  aad_tenant_id         = var.aad_tenant_id
  aad_allowed_audiences = var.aad_allowed_audiences

  app_settings = merge(
    var.frontend_app_settings,
    {
      "AAD_CLIENT_SECRET" = var.aad_client_secret
    }
  )

  always_on          = false # Free tier doesn't support always on
  health_check_path  = "/_stcore/health"
  log_retention_days = 7

  tags = local.common_tags
}
