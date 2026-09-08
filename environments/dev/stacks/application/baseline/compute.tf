# =============================================================================
# infra/stacks/application/baseline/compute.tf
#
# Managed Identity for the baseline workload.
# This identity is used by workload modules (AKS, app services, etc.)
# to authenticate against Azure services without credentials.
# =============================================================================

module "managed_identity" {
  source    = "../../../modules/managed-identity"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
