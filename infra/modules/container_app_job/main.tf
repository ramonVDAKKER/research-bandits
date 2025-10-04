terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_container_app_job" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  container_app_environment_id  = var.container_app_environment_id

  replica_timeout_in_seconds = var.replica_timeout_in_seconds
  replica_retry_limit        = var.replica_retry_limit

  manual_trigger_config {
    parallelism              = var.parallelism
    replica_completion_count = var.replica_completion_count
  }

  template {
    container {
      name   = "backend"
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.managed_identity_id
  }

  tags = var.tags
}
