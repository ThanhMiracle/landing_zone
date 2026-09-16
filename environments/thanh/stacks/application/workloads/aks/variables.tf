# infra/stacks/application/workloads/aks/variables.tf

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
  description = "Azure region where resources will be deployed. Example: 'southeastasia'."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet from the baseline stack. Used for subnet lookups and network integration."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault from the baseline stack. Used for secret storage and CSI driver integration."
  type        = string
}

variable "managed_identity_id" {
  description = "Resource ID of the user-assigned managed identity from the baseline stack. Used for workload identity."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing resource group (from the baseline stack) where the AKS cluster will be deployed. Sourced from dependency.baseline.outputs.spoke_resource_group_name."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace from the management stack. Used for OMS agent monitoring add-on."
  type        = string
}

variable "aks_subnet_id" {
  description = "Resource ID của subnet 'aks' từ baseline stack. Null = dùng default VNet (backward compat)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with mandatory tags (Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}
