terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_linux_web_app" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    always_on = var.always_on

    application_stack {
      docker_registry_url      = "https://${var.acr_login_server}"
      docker_image_name        = var.container_image
      docker_registry_username = null
      docker_registry_password = null
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      "WEBSITES_PORT"                       = "8000"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    }
  )

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    unauthenticated_action = "RedirectToLoginPage"

    login {
      token_store_enabled = true
    }

    active_directory_v2 {
      client_id                  = var.aad_client_id
      tenant_auth_endpoint       = "https://login.microsoftonline.com/${var.aad_tenant_id}/v2.0"
      allowed_audiences          = var.aad_allowed_audiences
      client_secret_setting_name = var.aad_client_secret_name
    }
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = var.log_retention_days
        retention_in_mb   = 35
      }
    }
  }

  https_only = true

  tags = var.tags
}
