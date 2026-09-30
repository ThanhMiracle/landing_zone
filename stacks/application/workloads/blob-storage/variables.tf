variable "subscription_id" {
  description = "Azure subscription ID that hosts the application workloads."
  type        = string
}

variable "name_prefix" {
  description = "Lowercase prefix used in resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "resource_group_name" {
  description = "Baseline spoke resource group that hosts the storage account."
  type        = string
}

variable "aks_kubelet_identity_object_id" {
  description = "Object ID of the deployed AKS kubelet managed identity that receives Blob Data Contributor."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace ID for Blob diagnostics."
  type        = string
  default     = null
}

variable "adopt_existing_diagnostic_setting" {
  description = "Whether to import an existing Blob diagnostic setting into this stack's Terraform state. Enable only for a one-time state adoption."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}
