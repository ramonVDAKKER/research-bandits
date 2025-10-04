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
  description = "SKU for App Service Plan (F1, B1-B3, S1-S3, P1v2-P3v3, etc.)"
  type        = string
  default     = "F1"

  validation {
    condition     = can(regex("^(F1|B[1-3]|S[1-3]|P[1-3]v[23]|I[1-3]v2|WS[1-3])$", var.sku_name))
    error_message = "sku_name must be a valid App Service Plan SKU (F1, B1-B3, S1-S3, P1v2-P3v3, I1v2-I3v2, WS1-WS3)."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
