# infra/stacks/application/workloads/aks/outputs.tf
# Outputs consumed by downstream stacks (if any) and surfaced via terragrunt dependency blocks.

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster. Sourced from modules/aks cluster_id output."
  value       = module.aks.cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster, following the naming convention: {name_prefix}-{environment}-aks."
  value       = "${var.name_prefix}-${var.environment}-aks"
}

output "aks_node_resource_group" {
  description = "Name of the auto-generated node resource group created by AKS to hold cluster infrastructure resources (VMs, disks, NICs). Follows Azure default pattern: MC_{resource_group}_{cluster_name}_{location}."
  value       = "MC_${var.resource_group_name}_${var.name_prefix}-${var.environment}-aks_${var.location}"
}
