# infra/stacks/application/workloads/redis/main.tf
# Workload template: Azure Cache for Redis
# Dependencies: baseline (spoke_vnet_id, key_vault_id, managed_identity_id, resource_group_name)
#               management (log_analytics_workspace_id)

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.0"
      configuration_aliases = [azurerm.workload]
    }
  }
}

module "redis" {
  source = "../../../../modules/redis-cache"

  providers = {
    azurerm = azurerm.workload
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = "${var.name_prefix}-${var.environment}-spoke-rg"

  # SKU defaults: Standard C1 — override via env.hcl inputs if needed
  sku_name      = "Standard"
  capacity      = 1
  redis_version = "6"

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# R8: Diagnostic Settings — gửi Redis logs về Log Analytics workspace
module "redis_diagnostics" {
  source = "../../../../modules/diagnostic-settings"
  count  = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  name                       = "${var.name_prefix}-${var.environment}-redis-diag"
  target_resource_id         = module.redis.redis_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log_categories    = ["ConnectedClientList"]
  metric_categories = ["AllMetrics"]
}
