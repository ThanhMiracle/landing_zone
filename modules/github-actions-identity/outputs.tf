output "id" {
  description = "Resource ID of the GitHub Actions user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "client_id" {
  description = "Client ID to configure as AZURE_CLIENT_ID in the authorized GitHub repository."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "Principal ID receiving AcrPush on the registry."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "federated_credential_id" {
  description = "Resource ID of the GitHub Actions federated identity credential."
  value       = azurerm_federated_identity_credential.github_actions.id
}
