# =============================================================================
# infra/stacks/application/workloads/vm-bastion/variables.tf
# Input variables for the VM-Bastion workload stack.
# Values are injected by terragrunt.hcl from env.hcl locals and
# dependency outputs (baseline stack).
# =============================================================================

variable "subscription_id" {
  description = "Azure Subscription ID for the application / workload subscription where the VM and Bastion Host are deployed."
  type        = string
}

variable "name_prefix" {
  description = "Short project prefix used in all resource names (e.g. 'myproject'). Maximum 10 lowercase characters. Combined with environment to form names like 'myproject-dev-vm'."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'staging', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "location" {
  description = "Azure region where resources are deployed (e.g. 'southeastasia'). Must match the region of the spoke VNet."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke Virtual Network (output from the baseline stack). Used to derive subnet IDs via data sources."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault (output from the baseline stack). Reserved for future use — e.g. storing VM admin SSH keys or Bastion session secrets."
  type        = string
}

variable "managed_identity_id" {
  description = "Resource ID of the User-Assigned Managed Identity (output from the baseline stack). Assigned to the VM so it can authenticate to Azure services without credentials."
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Name of the spoke Resource Group (output from the baseline stack). All VM-Bastion resources are deployed into this resource group."
  type        = string
}

variable "tags" {
  description = "Mandatory tags map (Project, Environment, ManagedBy = 'terraform') passed from env.hcl common_tags. Additional workload-specific tags may be merged by the caller."
  type        = map(string)
  default     = {}
}
