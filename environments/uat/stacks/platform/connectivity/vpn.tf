# =============================================================================
# infra/stacks/platform/connectivity/vpn.tf
# Azure VPN Gateway — optional hub component.
# Deployed only when var.deploy_vpn_gateway = true (count = 1).
# Provisioning takes 30–45 minutes on first apply — expected behavior.
# =============================================================================

module "vpn_gateway" {
  source = "../../../modules/vpn-gateway"
  count  = var.deploy_vpn_gateway ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  gateway_subnet_id   = module.hub_vnet.subnet_ids["GatewaySubnet"]
  tags                = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
