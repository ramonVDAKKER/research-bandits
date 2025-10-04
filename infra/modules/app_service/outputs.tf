output "id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.main.id
}

output "name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "outbound_ip_addresses" {
  description = "Outbound IP addresses"
  value       = azurerm_linux_web_app.main.outbound_ip_addresses
}
