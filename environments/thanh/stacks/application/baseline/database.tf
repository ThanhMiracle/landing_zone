# =============================================================================
# infra/stacks/application/baseline/database.tf
#
# Key Vault for the baseline workload.
# Key Vault is a foundational resource for the baseline stack — it stores
# secrets and keys consumed by workload modules (AKS, app services, etc.).
#
# Provider alias: azurerm.workload (all resources in the app subscription)
# Requirements: R8.1–R8.7, R15.2, R15.3
# =============================================================================

module "key_vault" {
  source    = "../../../modules/key-vault"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name

  # Tenant ID from the current Azure client config (data source in main.tf)
  tenant_id = data.azurerm_client_config.current.tenant_id

  # Production defaults — purge protection on, standard SKU
  sku_name                   = "standard"
  enable_purge_protection    = true
  soft_delete_retention_days = 90

  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# Workspace-based Application Insights shares the central Log Analytics
# workspace from the management stack.
module "application_insights" {
  source    = "../../../modules/app-insights"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"

  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
