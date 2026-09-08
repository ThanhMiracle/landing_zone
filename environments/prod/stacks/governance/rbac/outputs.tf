# infra/stacks/governance/rbac/outputs.tf
# R9, R15.8

output "assignment_ids" {
  description = "Map role assignment resource IDs, keyed by assignment name."
  value       = module.rbac.assignment_ids
}
