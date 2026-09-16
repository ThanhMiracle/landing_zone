# =============================================================================
# infra/stacks/application/baseline/networking.tf
#
# Spoke VNet and related network resources:
#   - Spoke Virtual Network with subnets
#   - Network Security Group (attached to first non-Bastion subnet)
#   - VNet Peering hub ↔ spoke (cross-subscription, conditional on valid hub_vnet_id)
#   - Forced-Tunneling Route Table (conditional on firewall_private_ip being set)
# =============================================================================

# ---------------------------------------------------------------------------
# Spoke VNet
# ---------------------------------------------------------------------------
module "vnet" {
  source    = "../../../modules/vnet"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.app_vnet_address_space
  subnets             = var.app_subnets
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Network Security Group — attached to first non-AzureBastionSubnet subnet
# ---------------------------------------------------------------------------
module "nsg" {
  source    = "../../../modules/nsg"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id = element(
    [for k, v in module.vnet.subnet_ids : v if k != "AzureBastionSubnet"],
    0
  )
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------------------
# VNet Peering — hub ↔ spoke (cross-subscription)
# Only deployed when hub_vnet_id is a valid Azure VNet resource ID.
# The vnet-peering module validates the format: must match the full ARM ID pattern.
# When connectivity stack is skipped, hub_vnet_id = "" so count = 0.
# ---------------------------------------------------------------------------
locals {
  hub_vnet_id_is_valid = can(
    regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$",
      var.hub_vnet_id
    )
  )
}

module "hub_peering" {
  count  = local.hub_vnet_id_is_valid ? 1 : 0
  source = "../../../modules/vnet-peering"

  providers = {
    azurerm.hub   = azurerm.connectivity # hub-side peering created in connectivity subscription
    azurerm.spoke = azurerm.workload     # spoke-side peering created in workload subscription
  }

  name_prefix               = var.name_prefix
  environment               = var.environment
  hub_vnet_id               = var.hub_vnet_id
  spoke_vnet_id             = module.vnet.vnet_id
  hub_resource_group_name   = var.hub_resource_group_name
  spoke_resource_group_name = module.resource_group.name
}

# ---------------------------------------------------------------------------
# Forced-Tunneling Route Table — routes 0.0.0.0/0 via Azure Firewall
# CRITICAL: AzureBastionSubnet is excluded — Bastion requires direct internet.
# Only deployed when firewall_private_ip is a non-null, non-empty string.
# ---------------------------------------------------------------------------
locals {
  firewall_ip_is_set = var.firewall_private_ip != null && var.firewall_private_ip != ""
}

module "forced_tunneling_rt" {
  count     = local.firewall_ip_is_set ? 1 : 0
  source    = "../../../modules/route-table"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  routes = {
    internet = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  }

  # Exclude AzureBastionSubnet — Bastion needs direct internet, must not go through firewall
  subnet_ids = { for subnet_name, subnet in var.app_subnets : subnet_name => module.vnet.subnet_ids[subnet_name] if subnet_name != "AzureBastionSubnet" }
}
