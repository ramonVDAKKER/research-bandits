output "id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "Login server URL for the Container Registry"
  value       = azurerm_container_registry.main.login_server
}
