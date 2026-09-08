output "id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "The Azure region where the resource group is located"
  value       = azurerm_resource_group.this.location
}
