output "dns_resolver_id" {
  description = "Resource ID of the Azure Private DNS Resolver."
  value       = azurerm_private_dns_resolver.this.id
}

output "inbound_endpoint_ip" {
  description = "Private IP address of the DNS Resolver inbound endpoint. Configure this IP as the DNS server on spoke VNets so their VMs resolve private DNS zones via the hub resolver."
  value       = azurerm_private_dns_resolver_inbound_endpoint.this.ip_configurations[0].private_ip_address
}
