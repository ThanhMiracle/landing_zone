output "postgresql_server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server. Use this to reference the server in RBAC assignments, diagnostic settings, or private endpoint configurations."
  value       = module.postgresql.server_id
}

output "postgresql_fqdn" {
  description = "Fully qualified domain name (FQDN) of the PostgreSQL Flexible Server. Use this as the hostname for application connection strings."
  value       = module.postgresql.server_fqdn
}
