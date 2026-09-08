# =============================================================================
# infra/stacks/platform/connectivity/firewall.tf
# Azure Firewall — conditional hub component.
# Deployed only when var.deploy_firewall = true (count = 1).
# When deploy_firewall = false, no azurerm_firewall resource is created (count = 0).
# =============================================================================

module "firewall" {
  source = "../../../modules/firewall"
  count  = var.deploy_firewall ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.hub_vnet.subnet_ids["AzureFirewallSubnet"]
  tags                = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
