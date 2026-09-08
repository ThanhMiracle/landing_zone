variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags merged with mandatory tags"
  type        = map(string)
  default     = {}
}

variable "sku_name" {
  description = "The SKU of the Redis cache. Allowed values: Basic, Standard, Premium"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "The size of the Redis cache. For Basic/Standard: 0-6. For Premium: 1-5."
  type        = number
  default     = 1
}

variable "redis_version" {
  description = "The Redis version. Allowed values: 4, 6"
  type        = string
  default     = "6"
}
