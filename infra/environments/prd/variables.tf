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

variable "acr_allowed_ips" {
  description = "List of IP addresses/CIDR ranges allowed to access ACR (only applies to Premium SKU)"
  type        = list(string)
  default     = []
}
