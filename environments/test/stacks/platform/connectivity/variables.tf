variable "subscription_id" {
  description = "Azure Subscription ID for the connectivity (hub networking) subscription."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used in resource names: {name_prefix}-{environment}-{suffix}. Lowercase, max 10 characters."
  type        = string
}

variable "environment" {
  description = "Deployment environment label. Defaults to 'connectivity' for the hub stack."
  type        = string
  default     = "connectivity"
}

variable "location" {
  description = "Azure region for all connectivity resources."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with mandatory tags on all resources. Mandatory tags (Project, Environment, ManagedBy) are enforced by each module call."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Feature flags
# ---------------------------------------------------------------------------

variable "deploy_firewall" {
  description = "Set to true to deploy Azure Firewall in the hub VNet. Core component — recommended to keep enabled. When false, no azurerm_firewall resource is created."
  type        = bool
  default     = true
}

variable "deploy_vpn_gateway" {
  description = "Set to true to deploy an Azure VPN Gateway in the hub VNet. Provisioning takes 30–45 minutes on first apply."
  type        = bool
  default     = false
}

variable "deploy_dns_resolver" {
  description = "Set to true to deploy an Azure Private DNS Resolver in the hub VNet. Requires DnsResolverInboundSubnet (>= /28) in hub_subnets."
  type        = bool
  default     = false
}

variable "deploy_bastion" {
  description = "Set to true to deploy Azure Bastion in the hub VNet. Requires AzureBastionSubnet (>= /26) in hub_subnets."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Hub networking
# ---------------------------------------------------------------------------

variable "hub_address_space" {
  description = "Address space(s) for the hub VNet, e.g. [\"10.0.0.0/16\"]. Must not overlap with spoke VNet address spaces."
  type        = list(string)
}

variable "hub_subnets" {
  description = <<-EOT
    Map of subnets to create in the hub VNet. Each entry requires address_prefixes.
    Minimum required subnets:
      - AzureFirewallSubnet        : >= /26 (required when deploy_firewall = true)
      - GatewaySubnet              : >= /27 (required when deploy_vpn_gateway = true)
      - DnsResolverInboundSubnet   : >= /28 (required when deploy_dns_resolver = true)
      - AzureBastionSubnet         : >= /26 (required when deploy_bastion = true)
  EOT
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    AzureFirewallSubnet = {
      address_prefixes = ["10.0.0.0/26"]
    }
    GatewaySubnet = {
      address_prefixes = ["10.0.0.64/27"]
    }
    DnsResolverInboundSubnet = {
      address_prefixes = ["10.0.0.96/28"]
    }
  }
}
