output "bastion_id" {
  description = "The resource ID of the Azure Bastion Host"
  value       = azurerm_bastion_host.this.id
}

output "bastion_name" {
  description = "The name of the Azure Bastion Host"
  value       = azurerm_bastion_host.this.name
}
