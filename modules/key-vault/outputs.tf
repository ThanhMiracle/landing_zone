output "key_vault_id" {
  description = "The resource ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault, used for accessing keys and secrets"
  value       = azurerm_key_vault.this.vault_uri
}

output "key_ids" {
  description = "Map of Key Vault key names to their versioned resource IDs"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.id }
}

output "secret_ids" {
  description = "Map of Key Vault secret names to their versioned resource IDs"
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.id }
  sensitive   = true
}
