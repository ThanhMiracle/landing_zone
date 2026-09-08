# infra/stacks/platform/identity/outputs.tf

output "identity_resource_group_name" {
  description = "Tên của identity placeholder resource group. Format: {name_prefix}-{environment}-identity-rg."
  value       = module.resource_group.name
}
