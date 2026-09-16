variable "subscription_id" {
  description = "Azure Subscription ID where the PostgreSQL Flexible Server will be deployed."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myproject'). Combined with environment to produce the server name."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'staging', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "location" {
  description = "Azure region where the PostgreSQL Flexible Server will be created (e.g. 'southeastasia')."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet from the baseline stack. Used to look up the delegated subnet for PostgreSQL."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the spoke resource group from the baseline stack."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault from the baseline stack. Used for customer-managed encryption key (CMK) if required."
  type        = string
}

variable "managed_identity_id" {
  description = "Resource ID of the User-Assigned Managed Identity from the baseline stack. Used for Key Vault access and CMK."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace from the management stack. Used for diagnostic settings and monitoring."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources. Should include at minimum Project, Environment, and ManagedBy keys."
  type        = map(string)
  default     = {}
}

variable "postgresql_admin_password" {
  description = "Administrator password for the PostgreSQL Flexible Server. Mark sensitive — inject via environment variable or CI secret, never hardcode."
  type        = string
  sensitive   = true
  default     = null
}
