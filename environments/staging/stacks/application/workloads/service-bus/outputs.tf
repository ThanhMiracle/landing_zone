# infra/stacks/application/workloads/service-bus/outputs.tf
#
# Outputs consumed by downstream stacks (if any) and surfaced via
# Terragrunt dependency blocks.
#
# Requirements: R9.5, R13.5–R13.7

output "servicebus_namespace_id" {
  description = "Resource ID of the Service Bus Namespace. Sourced from modules/service-bus namespace_id output."
  value       = module.service_bus.namespace_id
}

output "servicebus_namespace_name" {
  description = "Name of the Service Bus Namespace, following the naming convention: {name_prefix}-{environment}-servicebus."
  value       = module.service_bus.namespace_name
}
