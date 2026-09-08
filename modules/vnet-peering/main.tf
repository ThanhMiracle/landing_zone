terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.0"
      configuration_aliases = [azurerm.hub, azurerm.spoke]
    }
  }
}

# Hub → Spoke peering (created in hub subscription)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub

  name                      = "${var.name_prefix}-${var.environment}-peer-hub-to-spoke"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = element(split("/", var.hub_vnet_id), length(split("/", var.hub_vnet_id)) - 1)
  remote_virtual_network_id = var.spoke_vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = var.allow_gateway_transit
  use_remote_gateways     = false
}

# Spoke → Hub peering (created in workload subscription)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  provider = azurerm.spoke

  name                      = "${var.name_prefix}-${var.environment}-peer-spoke-to-hub"
  resource_group_name       = var.spoke_resource_group_name
  virtual_network_name      = element(split("/", var.spoke_vnet_id), length(split("/", var.spoke_vnet_id)) - 1)
  remote_virtual_network_id = var.hub_vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = var.allow_gateway_transit
}
