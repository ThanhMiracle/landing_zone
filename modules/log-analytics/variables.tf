variable "name_prefix" {
  description = "Prefix used for naming all resources in this module."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, uat, pre-production, prod)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the Log Analytics Workspace."
  type        = string
}

variable "location" {
  description = "Azure region where the Log Analytics Workspace will be created."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "SKU of the Log Analytics Workspace. Allowed value: PerGB2018."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Number of days to retain logs in the workspace. Valid range: 30–730 days."
  type        = number
  default     = 90
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB. Set to -1 (default) for unlimited ingestion."
  type        = number
  default     = -1
}
