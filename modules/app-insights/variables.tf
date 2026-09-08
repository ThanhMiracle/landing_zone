variable "name_prefix" {
  description = "Prefix used for naming all resources in this module."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, uat, pre-production, prod)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create Application Insights."
  type        = string
}

variable "location" {
  description = "Azure region where Application Insights will be created."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

variable "workspace_id" {
  description = "Resource ID of the Log Analytics Workspace to link Application Insights to (workspace-based mode)."
  type        = string
}

variable "application_type" {
  description = "Type of Application Insights component. Allowed values: web, other."
  type        = string
  default     = "web"
}
