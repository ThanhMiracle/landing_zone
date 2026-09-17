output "storage_account_id" {
  description = "Resource ID of the application Blob Storage account."
  value       = module.blob_storage.storage_account_id
}

output "storage_account_name" {
  description = "Globally unique storage account name used by AKS Blob CSI mounts."
  value       = module.blob_storage.storage_account_name
}

output "blob_endpoint" {
  description = "Blob service endpoint for the application data container."
  value       = module.blob_storage.primary_blob_endpoint
}

output "container_ids" {
  description = "IDs of private Blob containers created for application data."
  value       = module.blob_storage.container_ids
}

output "aks_blob_data_contributor_assignment_id" {
  description = "RBAC assignment granting the AKS kubelet identity Blob Data Contributor access."
  value       = azurerm_role_assignment.aks_blob_data_contributor.id
}
