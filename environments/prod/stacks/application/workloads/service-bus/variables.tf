# infra/stacks/application/workloads/service-bus/variables.tf
#
# Requirements: R9.5, R9.9, R9.10, R9.12, R13.5–R13.7, R15.2, R15.3

variable "subscription_id" {
  description = "Azure Subscription ID for the workload (application) subscription."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names. Lowercase, max 10 characters. Example: 'myproject'."
  type        = string
}

variable "environment" {
  description = "Deployment environment name. Example: 'dev', 'staging', 'prod'."
  type        = string
}

variable "location" {
  description = "Azure region where the Service Bus Namespace will be deployed. Example: 'southeastasia'."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet from the baseline stack. Used for future private endpoint integration."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault from the baseline stack. Used for storing Service Bus connection strings as secrets."
  type        = string
}

variable "managed_identity_id" {
  description = "Resource ID of the user-assigned managed identity from the baseline stack. Used for identity-based access to Key Vault and Service Bus."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace from the management stack. Used for diagnostic settings and monitoring."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with mandatory tags (Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}
