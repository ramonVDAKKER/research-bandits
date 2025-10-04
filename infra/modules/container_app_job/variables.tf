variable "name" {
  description = "Name of the Container App Job"
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

variable "container_apps_environment_id" {
  description = "Container Apps Environment ID"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
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

variable "cpu" {
  description = "CPU allocation"
  type        = string
  default     = "0.25"
}

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "0.5Gi"
}

variable "replica_timeout_in_seconds" {
  description = "Maximum duration a replica can run"
  type        = number
  default     = 1800
}

variable "replica_retry_limit" {
  description = "Number of retries for failed replicas"
  type        = number
  default     = 1
}

variable "parallelism" {
  description = "Number of parallel replicas"
  type        = number
  default     = 1
}

variable "replica_completion_count" {
  description = "Number of replicas that need to complete"
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
