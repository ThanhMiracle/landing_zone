output "vpn_gateway_id" {
  description = "The resource ID of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.this.id
}

output "vpn_gateway_public_ip" {
  description = "The public IP address of the VPN Gateway frontend — share this with on-premises network admins for IPsec tunnel configuration"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}
