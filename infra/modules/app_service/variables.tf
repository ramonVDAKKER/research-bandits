variable "name" {
  description = "Name of the App Service"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "app_service_plan_id" {
  description = "App Service Plan ID"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy (e.g., research-bandits-frontend:latest)"
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server URL"
  type        = string
}

variable "managed_identity_id" {
  description = "Managed identity ID for ACR access"
  type        = string
}

variable "aad_client_id" {
  description = "Azure AD application client ID for authentication"
  type        = string
}

variable "aad_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "aad_allowed_audiences" {
  description = "Allowed audiences for Azure AD authentication"
  type        = list(string)
  default     = []
}

variable "aad_client_secret_name" {
  description = "Name of the app setting containing the Azure AD client secret"
  type        = string
  default     = "AAD_CLIENT_SECRET"
}

variable "app_settings" {
  description = "Additional app settings"
  type        = map(string)
  default     = {}
}

variable "always_on" {
  description = "Enable always on"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/_stcore/health"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
