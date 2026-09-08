output "storage_account_id" {
  description = "The resource ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "The name of the storage account (max 24 chars, lowercase, no dashes)."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "The primary blob service endpoint URL for the storage account."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account. Marked sensitive — do not print in logs."
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "container_ids" {
  description = "Map of container names to their resource IDs."
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}
