# =============================================================================
# infra/stacks/application/baseline/variables.tf
# Generic baseline stack — no environment-specific hardcoded values.
# All values are injected by Terragrunt via env.hcl and dependency outputs.
# =============================================================================

variable "subscription_id" {
  description = "Azure Subscription ID where the baseline workload resources (spoke VNet, Key Vault, Managed Identity) will be deployed."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in all resource names (e.g. 'myproject'). Must be lowercase and at most 10 characters to comply with Azure naming limits."
  type        = string
}

variable "environment" {
  description = "Deployment environment name, e.g. 'dev', 'staging', 'prod'. Used in resource naming convention: {name_prefix}-{environment}-{suffix}."
  type        = string
}

variable "location" {
  description = "Azure region for all baseline resources (e.g. 'southeastasia', 'eastus2')."
  type        = string
  default     = "southeastasia"
}

variable "github_repository" {
  description = "GitHub repository permitted to push images to the baseline ACR through OIDC."
  type        = string
}

variable "github_oidc_subject" {
  description = "Exact GitHub OIDC subject allowed to push images through the federated credential."
  type        = string
}

# =============================================================================
# Networking Variables — from env.hcl
# =============================================================================

variable "app_vnet_address_space" {
  description = "List of CIDR blocks for the spoke Virtual Network address space. Example: ['10.1.0.0/16']. Must not overlap with hub_address_space or other spoke VNets."
  type        = list(string)
}

variable "app_subnets" {
  description = <<-EOT
    Map of subnets to create inside the spoke VNet. Each key is used as the subnet name.

    Each subnet object supports:
      - address_prefixes    (required) list(string) — CIDR block(s) for the subnet
      - service_endpoints   (optional) list(string) — e.g. ["Microsoft.Storage", "Microsoft.KeyVault"]
      - delegation          (optional) object — enables service delegation on the subnet
          - name                         string  — delegation resource name, e.g. "delegation"
          - service_delegation:
              - name    string        — service name, e.g. "Microsoft.DBforPostgreSQL/flexibleServers"
              - actions list(string)  — allowed actions

    Note: 'AzureBastionSubnet' must be named exactly that to be excluded from forced-tunneling route tables.
  EOT
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    }))
  }))
}

# =============================================================================
# Dependency Outputs — from Connectivity stack (via Terragrunt dependency block)
# =============================================================================

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet (output from platform/connectivity stack). Required for cross-subscription VNet peering. Populated automatically by Terragrunt dependency; set to empty string when connectivity stack is skipped."
  type        = string
  default     = ""
}

variable "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall in the hub (output from platform/connectivity stack). Required for forced-tunneling route table. Nullable — null when deploy_firewall = false on the connectivity stack."
  type        = string
  nullable    = true
  default     = null
}

variable "firewall_public_ip" {
  description = "Azure Firewall public IP. The forced-tunneling route table adds a /32 Internet route for firewall-DNAT return traffic."
  type        = string
  nullable    = true
  default     = null
}

variable "hub_resource_group_name" {
  description = "Name of the resource group containing the hub VNet (output from platform/connectivity stack). Required for cross-subscription VNet peering."
  type        = string
  default     = ""
}

variable "dns_server_ip" {
  description = "DNS Resolver inbound endpoint IP (output from platform/connectivity stack). Null when deploy_dns_resolver = false. Used to configure custom DNS on the spoke VNet."
  type        = string
  nullable    = true
  default     = null
}

# =============================================================================
# Dependency Outputs — from Management stack (via Terragrunt dependency block)
# =============================================================================

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace (output from platform/management stack). Used for diagnostic settings on baseline resources."
  type        = string
  default     = ""
}

# =============================================================================
# Tags
# =============================================================================

variable "tags" {
  description = "Tags to merge with mandatory tags ({ Project, Environment, ManagedBy = 'terraform' }). Passed from env.hcl common_tags."
  type        = map(string)
  default     = {}
}
