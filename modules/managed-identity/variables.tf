variable "name_prefix" {
  description = "Prefix used in the managed identity name: {name_prefix}-{environment}-id"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, uat, pre-production, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the managed identity will be created"
  type        = string
}

variable "location" {
  description = "Azure region where the managed identity will be created"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with mandatory tags (Project, Environment, ManagedBy)"
  type        = map(string)
  default     = {}
}
