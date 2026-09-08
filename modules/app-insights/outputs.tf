output "instrumentation_key" {
  description = "The Instrumentation Key for Application Insights. Marked sensitive."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "The Connection String for Application Insights. Marked sensitive."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "app_id" {
  description = "The App ID associated with this Application Insights component."
  value       = azurerm_application_insights.this.app_id
}
