# =============================================================================
# infra/stacks/application/baseline/outputs.tf
#
# Exports the outputs required by downstream workload stacks.
# These values are consumed via Terragrunt dependency blocks in:
#   - stacks/application/workloads/aks/
#   - stacks/application/workloads/postgresql/
#   - stacks/application/workloads/vm-bastion/
#   - stacks/application/workloads/redis/
#   - stacks/application/workloads/service-bus/
#
# Requirements: R8.7, R13.1–R13.4, R6.8, R18.7, R15.8
# =============================================================================

output "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet deployed in the application subscription. Consumed by workload stacks for subnet lookups and private endpoint placement."
  value       = module.vnet.vnet_id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault deployed in the baseline stack. Consumed by workload stacks to store and retrieve secrets."
  value       = module.key_vault.key_vault_id
}

output "managed_identity_id" {
  description = "Resource ID of the user-assigned Managed Identity deployed in the baseline stack. Consumed by workload stacks (AKS, app services) for passwordless Azure authentication."
  value       = module.managed_identity.id
}

output "spoke_resource_group_name" {
  description = "Name of the resource group that contains all baseline spoke resources. Consumed by workload stacks that must deploy into the same resource group."
  value       = module.resource_group.name
}

output "aks_subnet_id" {
  description = "Resource ID của subnet 'aks' trong spoke VNet. Consumed by AKS workload stack để tích hợp VNet (R6)."
  value       = module.vnet.subnet_ids["aks"]
}
