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
  description = "Resource ID of the spoke VNet deployed in the application subscription."
  value       = module.vnet.vnet_id
}

output "spoke_resource_group_name" {
  description = "Name of the resource group that contains all baseline spoke resources."
  value       = module.resource_group.name
}

# -----------------------------------------------------------------------------
# Subnet outputs
# -----------------------------------------------------------------------------

output "aks_subnet_id" {
  description = "Resource ID of the AKS subnet in the spoke VNet."
  value       = module.vnet.subnet_ids["aks"]
}

output "data_subnet_id" {
  description = "Resource ID of the delegated data subnet used by PostgreSQL Flexible Server."
  value       = module.vnet.subnet_ids["data"]
}

# -----------------------------------------------------------------------------
# Shared platform resources
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "Resource ID of the Key Vault deployed in the baseline stack."
  value       = module.key_vault.key_vault_id
}

output "managed_identity_id" {
  description = "Resource ID of the user-assigned Managed Identity deployed in the baseline stack."
  value       = module.managed_identity.id
}

output "container_registry_id" {
  description = "Resource ID of the Azure Container Registry for workload images."
  value       = module.container_registry.registry_id
}

output "container_registry_login_server" {
  description = "Container Registry login server used by workload deployment pipelines."
  value       = module.container_registry.login_server
}

# -----------------------------------------------------------------------------
# Observability
# -----------------------------------------------------------------------------

output "application_insights_connection_string" {
  description = "Application Insights connection string for the Agent API and worker workloads."
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "Application Insights application ID for querying telemetry."
  value       = module.application_insights.app_id
}