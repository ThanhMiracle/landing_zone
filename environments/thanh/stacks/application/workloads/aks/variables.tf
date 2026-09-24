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

variable "key_vault_id" {
  description = "Resource ID of the Key Vault from the baseline stack. Used for secret storage and CSI driver integration."
  type        = string
}

variable "managed_identity_id" {
  description = "Resource ID of the user-assigned managed identity used by the AKS control plane."
  type        = string
}

variable "managed_identity_principal_id" {
  description = "Principal ID of the AKS control-plane managed identity."
  type        = string
}

variable "aks_route_table_id" {
  description = "Resource ID of the custom route table associated with the AKS subnet, or null when forced tunneling is disabled."
  type        = string
  nullable    = true
}

variable "container_registry_id" {
  description = "Resource ID of the Azure Container Registry used by AKS workloads."
  type        = string
}

variable "github_deploy_oidc_subject" {
  description = "Exact GitHub OIDC subject allowed to deploy to this AKS cluster."
  type        = string

  validation {
    condition     = startswith(var.github_deploy_oidc_subject, "repo:")
    error_message = "github_deploy_oidc_subject must be a GitHub Actions OIDC subject beginning with repo:."
  }
}

variable "outbound_type" {
  description = "AKS outbound routing mode. Use userDefinedRouting when the spoke subnet routes through Azure Firewall."
  type        = string

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer or userDefinedRouting."
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group (from the baseline stack) where the AKS cluster will be deployed. Sourced from dependency.baseline.outputs.spoke_resource_group_name."
  type        = string
}

variable "service_cidr" {
  description = "Kubernetes service CIDR, separate from the hub and spoke address spaces."
  type        = string
  nullable    = false
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP within the service CIDR."
  type        = string
  nullable    = false
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
