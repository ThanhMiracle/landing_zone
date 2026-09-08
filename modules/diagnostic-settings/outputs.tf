output "diagnostic_setting_id" {
  description = "The ID of the Monitor Diagnostic Setting."
  value       = azurerm_monitor_diagnostic_setting.this.id
}
