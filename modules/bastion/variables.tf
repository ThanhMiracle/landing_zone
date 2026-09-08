variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment, e.g. 'dev', 'prod'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for all resources in this module"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory tags (Project, Environment, ManagedBy)"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Resource ID of the AzureBastionSubnet subnet. The subnet must be named 'AzureBastionSubnet' and have a /26 or larger prefix."
  type        = string
}

variable "sku" {
  description = "SKU of the Azure Bastion Host. Allowed values: 'Basic' or 'Standard'."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be either 'Basic' or 'Standard'."
  }
}
