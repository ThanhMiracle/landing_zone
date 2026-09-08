output "lb_id" {
  description = "The resource ID of the Load Balancer"
  value       = azurerm_lb.this.id
}

output "lb_name" {
  description = "The name of the Load Balancer"
  value       = azurerm_lb.this.name
}

output "frontend_ip_address" {
  description = "The frontend IP address (public IP or private IP depending on lb_type)"
  value       = var.lb_type == "public" ? azurerm_public_ip.this[0].ip_address : azurerm_lb.this.frontend_ip_configuration[0].private_ip_address
}

output "backend_pool_id" {
  description = "The resource ID of the backend address pool"
  value       = azurerm_lb_backend_address_pool.this.id
}
