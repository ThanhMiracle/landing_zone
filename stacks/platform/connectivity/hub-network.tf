# =============================================================================
# infra/stacks/platform/connectivity/hub-network.tf
# Hub VNet — always deployed; subnets are determined by hub_subnets variable.
# =============================================================================

module "hub_vnet" {
  source = "../../../modules/vnet"

  providers = {
    azurerm = azurerm.connectivity
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.hub_address_space
  subnets             = var.hub_subnets
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
