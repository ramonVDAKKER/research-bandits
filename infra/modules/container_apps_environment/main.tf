resource "azurerm_container_app_environment" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = var.tags
}

# Managed identity for the Container Apps environment
resource "azurerm_user_assigned_identity" "container_apps" {
  name                = "${var.name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
