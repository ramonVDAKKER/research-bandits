variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "research-bandits"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

# Log Analytics
variable "log_analytics_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Container Registry
variable "acr_name" {
  description = "Name of the Azure Container Registry (alphanumeric only, globally unique)"
  type        = string
  default     = "acrresearchbanditsdev"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "acr_allowed_ips" {
  description = "List of IP addresses/CIDR ranges allowed to access ACR (only applies to Premium SKU)"
  type        = list(string)
  default     = []
}

# App Service Plan
variable "app_service_plan_sku" {
  description = "SKU for App Service Plan (F1 = Free, B1 = Basic)"
  type        = string
  default     = "F1"
}

# GitHub Actions Service Principal
variable "github_actions_sp_name" {
  description = "Display name of the GitHub Actions service principal"
  type        = string
  default     = "sp-github-actions-research-bandits"
}

# Backend Container App Job
variable "backend_env_vars" {
  description = "Environment variables for backend job"
  type        = map(string)
  default     = {}
}

# Frontend App Service - Azure AD Authentication
variable "aad_client_id" {
  description = "Azure AD application client ID for authentication"
  type        = string
  sensitive   = true
}

variable "aad_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "aad_client_secret" {
  description = "Azure AD application client secret"
  type        = string
  sensitive   = true
}

variable "aad_allowed_audiences" {
  description = "Allowed audiences for Azure AD authentication"
  type        = list(string)
  default     = []
}

variable "frontend_app_settings" {
  description = "Additional app settings for frontend"
  type        = map(string)
  default     = {}
}
