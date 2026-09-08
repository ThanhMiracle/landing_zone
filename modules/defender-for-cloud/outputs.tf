output "enabled_plans" {
  description = "List of resource type names for which Defender for Cloud (Standard tier) has been enabled by this module."
  value       = [for k, v in azurerm_security_center_subscription_pricing.this : v.resource_type]
}
