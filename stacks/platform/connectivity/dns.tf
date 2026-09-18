# =============================================================================
# infra/stacks/platform/connectivity/dns.tf
# Azure Private DNS Resolver — optional hub component.
# Deployed only when var.deploy_dns_resolver = true (count = 1).
# Requires DnsResolverInboundSubnet (>= /28) to be present in hub_subnets.
# =============================================================================

module "dns_resolver" {
  source = "../../../modules/dns-resolver"
  count  = var.deploy_dns_resolver ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_id             = module.hub_vnet.vnet_id
  inbound_subnet_id   = module.hub_vnet.subnet_ids["DnsResolverInboundSubnet"]
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
