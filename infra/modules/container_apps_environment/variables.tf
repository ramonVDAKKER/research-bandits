variable "name" {
  description = "Name of the Container Apps Environment"
  type        = string
}

variable "location" {
  description = "Azure region for the environment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  type        = string
}


variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
