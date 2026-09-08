# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to produce the storage account name."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the storage account."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Storage account settings
# ---------------------------------------------------------------------------

variable "account_tier" {
  description = "Performance tier of the storage account. 'Standard' or 'Premium'."
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication strategy. Allowed values: LRS, GRS, ZRS, GZRS, RA-GRS, RA-GZRS."
  type        = string
  default     = "LRS"
}

# ---------------------------------------------------------------------------
# Containers
# ---------------------------------------------------------------------------

variable "containers" {
  description = "Map of blob containers to create. Key = container name. access_type: 'private', 'blob', or 'container'."
  type = map(object({
    access_type = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Blob properties — versioning & soft delete
# ---------------------------------------------------------------------------

variable "enable_versioning" {
  description = "Enable blob versioning. When true, every write creates an immutable version."
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted blobs. Set to 0 to disable soft delete."
  type        = number
  default     = 7
}

# ---------------------------------------------------------------------------
# Customer-managed key (optional)
# ---------------------------------------------------------------------------

variable "customer_managed_key_id" {
  description = "Resource ID of the Key Vault key to use for customer-managed encryption. When null, Microsoft-managed keys are used."
  type        = string
  default     = null
}
