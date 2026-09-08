# =============================================================================
# infra/stacks/application/workloads/vm-bastion/outputs.tf
# Outputs consumed by the terragrunt dependency graph (upper-tier stacks)
# and exposed in the Terraform state for operational reference.
# =============================================================================

output "vm_id" {
  description = "Resource ID of the Linux Virtual Machine deployed in the spoke subscription. Use this to target the VM in RBAC assignments, policy exemptions, or monitoring rules."
  value       = module.vm.vm_id
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion Host deployed in the AzureBastionSubnet. Use this to configure diagnostic settings, RBAC access, or reference the host in network security policies."
  value       = module.bastion.bastion_id
}
