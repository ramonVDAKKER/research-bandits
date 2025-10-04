output "id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}

output "name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "default_domain" {
  description = "Default domain of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  description = "Static IP address of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.container_apps.principal_id
}

output "managed_identity_id" {
  description = "ID of the managed identity"
  value       = azurerm_user_assigned_identity.container_apps.id
}
