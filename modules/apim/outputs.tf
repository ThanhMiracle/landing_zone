output "apim_id" {
  description = "The resource ID of the API Management instance."
  value       = azurerm_api_management.this.id
}

output "gateway_url" {
  description = "The URL of the API Management gateway endpoint (e.g. 'https://{name}.azure-api.net')."
  value       = azurerm_api_management.this.gateway_url
}

output "management_api_url" {
  description = "The URL of the API Management management API endpoint."
  value       = azurerm_api_management.this.management_api_url
}

output "principal_id" {
  description = "The principal (object) ID of the system-assigned managed identity for the API Management instance. Used to assign RBAC roles."
  value       = azurerm_api_management.this.identity[0].principal_id
}
