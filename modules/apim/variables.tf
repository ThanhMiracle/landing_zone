# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to produce the APIM instance name."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the API Management instance."
  type        = string
}

variable "location" {
  description = "Azure region for the API Management instance (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# API Management
# ---------------------------------------------------------------------------

variable "sku_name" {
  description = "SKU name and capacity for the API Management instance. Format: '<SKU>_<capacity>'. Allowed values: 'Developer_1', 'Basic_1', 'Standard_1', 'Premium_1'."
  type        = string
  default     = "Developer_1"
}

variable "publisher_name" {
  description = "The name of the publisher/organization for the API Management instance. Required."
  type        = string
}

variable "publisher_email" {
  description = "The email address of the publisher/organization for the API Management instance. Required."
  type        = string
}

variable "virtual_network_type" {
  description = "The type of VNet integration for the API Management instance. Allowed values: null (no VNet), 'External' (accessible from internet via VNet), 'Internal' (only accessible within VNet). 'External' and 'Internal' require Premium SKU."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the subnet to use for VNet integration. Required when virtual_network_type is 'External' or 'Internal'."
  type        = string
  default     = null
}
