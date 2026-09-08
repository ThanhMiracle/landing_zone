output "namespace_id" {
  description = "The resource ID of the Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "The name of the Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.name
}

output "default_primary_connection_string" {
  description = "The primary connection string for the Service Bus Namespace default authorization rule. Sensitive — contains a shared access key."
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "queue_ids" {
  description = "Map of queue name to resource ID for all queues created in the namespace."
  value       = { for k, q in azurerm_servicebus_queue.this : k => q.id }
}

output "topic_ids" {
  description = "Map of topic name to resource ID for all topics created in the namespace."
  value       = { for k, t in azurerm_servicebus_topic.this : k => t.id }
}
