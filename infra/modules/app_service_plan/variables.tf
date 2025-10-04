variable "name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "location" {
  description = "Azure region for the plan"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU for App Service Plan (e.g., F1 for Free, B1 for Basic)"
  type        = string
  default     = "F1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
