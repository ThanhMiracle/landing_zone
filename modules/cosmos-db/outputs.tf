output "account_id" {
  description = "The resource ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "account_name" {
  description = "The name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "The endpoint URI of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "primary_key" {
  description = "The primary master key for the Cosmos DB account. Handle with care — store in Key Vault."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "connection_strings" {
  description = "Map of SQL connection strings for the Cosmos DB account (primary, primary_readonly, secondary, secondary_readonly)."
  value = {
    primary            = azurerm_cosmosdb_account.this.primary_sql_connection_string
    primary_readonly   = azurerm_cosmosdb_account.this.primary_readonly_sql_connection_string
    secondary          = azurerm_cosmosdb_account.this.secondary_sql_connection_string
    secondary_readonly = azurerm_cosmosdb_account.this.secondary_readonly_sql_connection_string
  }
  sensitive = true
}
