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
  description = "SKU for App Service Plan (B1+ required for Linux + custom containers)"
  type        = string
  default     = "B1"

  validation {
    condition     = can(regex("^(B[1-3]|S[1-3]|P[1-3]V[2-3]|I[1-3]V[2]|WS[1-3])$", var.sku_name))
    error_message = "sku_name must be B1 or higher (B1-B3, S1-S3, P1V2-P3V3, etc.) for Linux App Service with custom containers. F1 is not supported."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
