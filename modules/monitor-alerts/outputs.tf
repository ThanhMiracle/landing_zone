output "action_group_id" {
  description = "The resource ID of the Monitor Action Group."
  value       = azurerm_monitor_action_group.this.id
}

output "alert_ids" {
  description = "Map of metric alert resource IDs, keyed by the same keys as var.metric_alerts."
  value       = { for k, v in azurerm_monitor_metric_alert.this : k => v.id }
}
