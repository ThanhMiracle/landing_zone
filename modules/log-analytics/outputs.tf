output "workspace_id" {
  description = "The Log Analytics Workspace GUID (used with diagnostic settings and monitoring alerts)."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "workspace_key" {
  description = "The primary shared key for the Log Analytics Workspace. Marked sensitive."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "workspace_name" {
  description = "The name of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_resource_id" {
  description = "The ARM resource ID of the Log Analytics Workspace (used with diagnostic settings)."
  value       = azurerm_log_analytics_workspace.this.id
}
