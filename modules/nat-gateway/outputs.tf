output "nat_gateway_id" {
  description = "The resource ID of the NAT Gateway"
  value       = azurerm_nat_gateway.this.id
}

output "public_ip_address" {
  description = "The public IP address allocated to the NAT Gateway"
  value       = azurerm_public_ip.this.ip_address
}
