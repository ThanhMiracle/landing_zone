output "registry_id" {
  description = "The resource ID of the Container Registry."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "The URL that can be used to log into the Container Registry (e.g. myappdevacr.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "registry_name" {
  description = "The name of the Container Registry."
  value       = azurerm_container_registry.this.name
}
