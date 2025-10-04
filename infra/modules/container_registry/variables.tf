variable "name" {
  description = "Name of the Container Registry (must be globally unique, alphanumeric only)"
  type        = string
}

variable "location" {
  description = "Azure region for the registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku" {
  description = "SKU for Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}


variable "container_apps_identity_principal_id" {
  description = "Principal ID of Container Apps managed identity for ACR pull access"
  type        = string
}

variable "app_service_identity_principal_id" {
  description = "Principal ID of App Service managed identity for ACR pull access"
  type        = string
}

variable "github_actions_sp_object_id" {
  description = "Object ID of GitHub Actions service principal for ACR push access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
