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
