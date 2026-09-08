output "app_service_id" {
  description = "The resource ID of the Linux Web App."
  value       = azurerm_linux_web_app.this.id
}

output "default_hostname" {
  description = "The default hostname of the Web App (e.g. myapp-dev-app.azurewebsites.net)."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "principal_id" {
  description = "The principal (object) ID of the system-assigned Managed Identity of the Web App. Use this to grant RBAC permissions (e.g. Key Vault access)."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
