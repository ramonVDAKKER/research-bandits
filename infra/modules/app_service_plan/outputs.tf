output "id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.app_service.principal_id
}

output "managed_identity_id" {
  description = "ID of the managed identity"
  value       = azurerm_user_assigned_identity.app_service.id
}
