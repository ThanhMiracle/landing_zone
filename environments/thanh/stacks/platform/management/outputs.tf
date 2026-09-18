# infra/stacks/platform/management/outputs.tf
# Outputs consumed by downstream stacks via Terragrunt dependency blocks:
#   - baseline stack: log_analytics_workspace_id
#   - ALL workload stacks: log_analytics_workspace_id
# See: infra/stacks/application/baseline/terragrunt.hcl and workloads/*/terragrunt.hcl

output "log_analytics_workspace_id" {
  value       = module.log_analytics.workspace_resource_id
  description = "ARM resource ID of the central Log Analytics workspace. Consumed by Baseline_Stack and all Workload_Stacks via dependency block output."
}
