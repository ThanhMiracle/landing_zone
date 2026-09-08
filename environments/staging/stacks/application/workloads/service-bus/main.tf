# infra/stacks/application/workloads/service-bus/main.tf
#
# Workload template: Azure Service Bus Namespace deployed in the application
# spoke subscription.
#
# Skip condition in terragrunt.hcl uses deploy_service_bus flag per R2.
#
# Dependencies:
#   - baseline stack : spoke_vnet_id, key_vault_id, managed_identity_id
#   - management stack: log_analytics_workspace_id
#
# Provider alias "azurerm.workload" is injected by Terragrunt via
# provider_generated.tf (generated in terragrunt.hcl).
#
# Requirements: R9.5, R9.9, R9.10, R9.12, R13.5–R13.7, R15.2, R15.3

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.0"
      configuration_aliases = [azurerm.workload]
    }
  }
}

# ---------------------------------------------------------------------------
# Mandatory tags — merged with any caller-supplied tags (R15.2, R15.3)
# ---------------------------------------------------------------------------

locals {
  mandatory_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------
# Service Bus Namespace
# Naming: ${var.name_prefix}-${var.environment}-servicebus  (R15.2)
# ---------------------------------------------------------------------------

module "service_bus" {
  source = "../../../../modules/service-bus"

  providers = {
    azurerm = azurerm.workload
  }

  name_prefix         = var.name_prefix
  environment         = "${var.environment}-servicebus"
  location            = var.location
  resource_group_name = "${var.name_prefix}-${var.environment}-spoke-rg"

  # SKU default: Standard — supports both queues and topics
  sku = "Standard"

  tags = local.mandatory_tags
}

# R8: Diagnostic Settings — gửi Service Bus logs về Log Analytics workspace
module "service_bus_diagnostics" {
  source = "../../../../modules/diagnostic-settings"
  count  = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  name                       = "${var.name_prefix}-${var.environment}-sb-diag"
  target_resource_id         = module.service_bus.namespace_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log_categories    = ["OperationalLogs", "VNetAndIPFilteringLogs", "RuntimeAuditLogs"]
  metric_categories = ["AllMetrics"]
}
