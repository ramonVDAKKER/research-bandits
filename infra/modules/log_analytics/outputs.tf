output "id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_id" {
  description = "Workspace ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}
