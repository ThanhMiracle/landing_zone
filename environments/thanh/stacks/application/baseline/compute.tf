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

# Container images for the Agent API, orchestrator, and workers will be stored
# here. The workloads themselves are intentionally deployed separately.
module "container_registry" {
  source    = "../../../modules/container-registry"
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

# GitHub Actions receives only AcrPush on this registry through OIDC. It is a
# separate identity from the AKS control-plane identity above.
module "github_actions_acr_push_identity" {
  source    = "../../../modules/github-actions-identity"
  providers = { azurerm = azurerm.workload }

  name_prefix           = var.name_prefix
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.resource_group.name
  container_registry_id = module.container_registry.registry_id
  github_repository     = var.github_repository
  github_oidc_subject   = var.github_oidc_subject

  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
