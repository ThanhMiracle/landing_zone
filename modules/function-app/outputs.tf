output "function_app_id" {
  description = "The resource ID of the Linux Function App."
  value       = azurerm_linux_function_app.this.id
}

output "default_hostname" {
  description = "The default hostname of the Function App (e.g. myapp-dev-func.azurewebsites.net)."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "principal_id" {
  description = "The principal (object) ID of the system-assigned Managed Identity of the Function App. Use this to grant RBAC permissions (e.g. Key Vault access)."
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}
