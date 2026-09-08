# infra/stacks/management-groups/outputs.tf

output "tenant_root_mg_id" {
  description = "Resource ID của Tenant Root Management Group."
  value       = module.tenant_root.management_group_id
}

output "platform_mg_id" {
  description = "Resource ID của Platform Management Group. Dùng khi gán platform subscriptions vào management group."
  value       = module.platform.management_group_id
}

output "application_mg_id" {
  description = "Resource ID của Application Landing Zones Management Group. Dùng khi gán application subscriptions."
  value       = module.application.management_group_id
}
