output "vm_id" {
  description = "The resource ID of the Linux Virtual Machine."
  value       = azurerm_linux_virtual_machine.this.id
}

output "private_ip_address" {
  description = "The private IP address assigned to the Network Interface of the VM."
  value       = azurerm_network_interface.this.private_ip_address
}

output "principal_id" {
  description = "The principal (object) ID of the system-assigned Managed Identity of the VM. Use this to grant RBAC permissions (e.g. Key Vault Secrets User, Storage Blob Data Reader)."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
