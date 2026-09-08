# infra/stacks/platform/security/outputs.tf

output "security_resource_group_name" {
  description = "Tên của security placeholder resource group. Format: {name_prefix}-{environment}-security-rg."
  value       = module.resource_group.name
}
