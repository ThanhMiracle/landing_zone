output "server_id" {
  description = "The resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.name
}
