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
