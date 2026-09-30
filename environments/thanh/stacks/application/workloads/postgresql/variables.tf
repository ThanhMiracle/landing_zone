variable "subscription_id" {
  description = "Azure Subscription ID where the PostgreSQL Flexible Server will be deployed."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier such as dev, staging, or prod."
  type        = string
}

variable "location" {
  description = "Azure region where the PostgreSQL Flexible Server will be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the application resource group from the baseline stack."
  type        = string
}

variable "data_subnet_id" {
  description = "Resource ID of the delegated data subnet used by PostgreSQL Flexible Server."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault from the baseline stack."
  type        = string
}

variable "managed_identity_id" {
  description = "Resource ID of the User-Assigned Managed Identity from the baseline stack."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace from the management stack."
  type        = string
}

variable "adopt_existing_resources" {
  description = "Whether to import existing PostgreSQL diagnostics and connection-secret resources into this stack's Terraform state. Enable only for a one-time state adoption."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "postgresql_admin_password" {
  description = "Administrator password for the PostgreSQL Flexible Server. Inject via environment variable or CI secret; never hardcode."
  type        = string
  sensitive   = true
  default     = null
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet from the baseline stack."
  type        = string
}
