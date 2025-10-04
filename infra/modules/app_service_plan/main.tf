resource "azurerm_service_plan" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

# Managed identity for App Service (for ACR pull and Entra auth)
resource "azurerm_user_assigned_identity" "app_service" {
  name                = "${var.name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
