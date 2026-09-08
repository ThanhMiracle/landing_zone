variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment name, e.g. 'dev', 'prod'"
  type        = string
}

variable "scope_type" {
  description = "Scope at which policy initiatives are assigned. Allowed values: 'subscription', 'resource_group', or 'management_group'"
  type        = string
  default     = "subscription"

  validation {
    condition     = contains(["subscription", "resource_group", "management_group"], var.scope_type)
    error_message = "scope_type must be 'subscription', 'resource_group', or 'management_group'."
  }
}

variable "management_group_id" {
  description = "Management Group resource ID. Required when scope_type is 'management_group'. Format: '/providers/Microsoft.Management/managementGroups/<name>'"
  type        = string
  default     = ""

  validation {
    condition     = var.scope_type != "management_group" || (var.scope_type == "management_group" && var.management_group_id != "")
    error_message = "management_group_id must be non-empty when scope_type is 'management_group'."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID. Required when scope_type is 'subscription'. Format: '/subscriptions/<uuid>'"
  type        = string
  default     = ""
}

variable "resource_group_id" {
  description = "Resource Group resource ID. Required when scope_type is 'resource_group'. Format: '/subscriptions/<uuid>/resourceGroups/<name>'"
  type        = string
  default     = ""
}

variable "deploy_azure_security_benchmark" {
  description = "Whether to assign the Azure Security Benchmark built-in policy initiative"
  type        = bool
  default     = false
}

variable "deploy_cis_foundations" {
  description = "Whether to assign the CIS Microsoft Azure Foundations Benchmark built-in policy initiative"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with the mandatory tags (Project, Environment, ManagedBy). Note: policy assignments do not support tags natively; these are tracked for metadata purposes"
  type        = map(string)
  default     = {}
}
