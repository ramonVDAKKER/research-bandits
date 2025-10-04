# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# Log Analytics
output "log_analytics_workspace_id" {
  description = "Workspace ID of the Log Analytics"
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = module.log_analytics.name
}

# Container Registry
output "acr_login_server" {
  description = "Login server URL for the Container Registry"
  value       = module.container_registry.login_server
}

output "acr_name" {
  description = "Name of the Container Registry"
  value       = module.container_registry.name
}


# Container Apps Environment
output "container_apps_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = module.container_apps_environment.id
}

output "container_apps_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = module.container_apps_environment.name
}

output "container_apps_default_domain" {
  description = "Default domain of the Container Apps Environment"
  value       = module.container_apps_environment.default_domain
}

output "container_apps_static_ip" {
  description = "Static IP address of the Container Apps Environment"
  value       = module.container_apps_environment.static_ip_address
}

output "container_apps_identity_id" {
  description = "Managed identity ID for Container Apps"
  value       = module.container_apps_environment.managed_identity_id
}

# App Service Plan
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = module.app_service_plan.id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = module.app_service_plan.name
}

output "app_service_identity_id" {
  description = "Managed identity ID for App Service"
  value       = module.app_service_plan.managed_identity_id
}

# Backend Job
output "backend_job_id" {
  description = "ID of the backend Container App Job"
  value       = module.backend_job.id
}

output "backend_job_name" {
  description = "Name of the backend Container App Job"
  value       = module.backend_job.name
}

# Frontend App
output "frontend_app_id" {
  description = "ID of the frontend App Service"
  value       = module.frontend_app.id
}

output "frontend_app_name" {
  description = "Name of the frontend App Service"
  value       = module.frontend_app.name
}

output "frontend_app_url" {
  description = "URL of the frontend App Service"
  value       = "https://${module.frontend_app.default_hostname}"
}
