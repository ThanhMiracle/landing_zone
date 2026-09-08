variable "name_prefix" {
  description = "Prefix used in the resource group name: {name_prefix}-{environment}-rg"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, uat, pre-production, prod)"
  type        = string
}

variable "location" {
  description = "Azure region where the resource group will be created"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with mandatory tags (Project, Environment, ManagedBy)"
  type        = map(string)
  default     = {}
}
