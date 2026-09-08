output "hub_to_spoke_peering_id" {
  description = "Resource ID of the hub-to-spoke VNet peering."
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "spoke_to_hub_peering_id" {
  description = "Resource ID of the spoke-to-hub VNet peering."
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}
