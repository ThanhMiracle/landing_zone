output "vnet_id" {
  description = "The resource ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The list of CIDR blocks assigned to the Virtual Network"
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID for all subnets created in this VNet"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}
