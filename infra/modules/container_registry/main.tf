resource "azurerm_container_registry" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  admin_enabled       = false # Use RBAC only (managed identities + service principal)

  # Network rules only supported on Premium SKU
  # Basic SKU: Access controlled via Azure RBAC (managed identities + service principal)
  public_network_access_enabled = var.sku == "Premium" && length(var.acr_allowed_ips) > 0 ? false : true

  tags = var.tags

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && length(var.acr_allowed_ips) > 0 ? [1] : []
    content {
      default_action = "Deny"
      ip_rule {
        for ip in var.acr_allowed_ips : {
          action   = "Allow"
          ip_range = ip
        }
      }
    }
  }
}

# Role assignment for Container Apps managed identity
resource "azurerm_role_assignment" "acr_pull_container_apps" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.container_apps_identity_principal_id
  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Role assignment for App Service managed identity
resource "azurerm_role_assignment" "acr_pull_app_service" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.app_service_identity_principal_id
  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Role assignment for GitHub Actions Service Principal (push + pull)
resource "azurerm_role_assignment" "acr_push_service_principal" {
  count                            = var.github_actions_sp_object_id != null ? 1 : 0
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPush" # Includes pull permissions
  principal_id                     = var.github_actions_sp_object_id
  skip_service_principal_aad_check = true

  lifecycle {
    ignore_changes = [principal_id]
  }
}
