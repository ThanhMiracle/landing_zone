output "firewall_id" {
  description = "The resource ID of the Azure Firewall"
  value       = azurerm_firewall.this.id
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall — use this as the next-hop IP in spoke route tables for forced tunneling"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "The public IP address of the Azure Firewall frontend"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "The resource ID of the Firewall Policy attached to this firewall"
  value       = azurerm_firewall_policy.this.id
}
