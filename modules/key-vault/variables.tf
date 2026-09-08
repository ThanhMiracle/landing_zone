variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment name, e.g. 'dev', 'prod'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where the Key Vault will be created"
  type        = string
}

variable "location" {
  description = "Azure region where the Key Vault will be deployed"
  type        = string
  default     = "southeastasia"
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID for the Key Vault"
  type        = string
}

variable "sku_name" {
  description = "SKU tier for the Key Vault. Allowed values: 'standard' or 'premium'"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be 'standard' or 'premium'."
  }
}

variable "enable_purge_protection" {
  description = "Whether to enable purge protection on the Key Vault. When true, the vault and its contents cannot be permanently deleted within the retention period"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days that soft-deleted items are retained before permanent deletion. Must be between 7 and 90"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "keys" {
  description = "Map of Key Vault keys to create. Key is the key name; value contains key_type, key_size, and key_opts"
  type = map(object({
    key_type = string
    key_size = number
    key_opts = list(string)
  }))
  default = {}
}

variable "secrets" {
  description = "Map of Key Vault secrets to create. Key is the secret name; value contains the secret value and optional expiration_date (RFC3339). Treat this variable as sensitive — avoid logging or displaying its contents"
  type = map(object({
    value           = string
    expiration_date = optional(string)
  }))
  default = {}
}

variable "network_acls" {
  description = "Network ACL configuration for the Key Vault. Set to null to allow all traffic"
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "tags" {
  description = "Additional tags to merge with the mandatory tags (Project, Environment, ManagedBy)"
  type        = map(string)
  default     = {}
}
