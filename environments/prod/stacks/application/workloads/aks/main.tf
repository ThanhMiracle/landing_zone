# infra/stacks/application/workloads/aks/main.tf
# Workload template: AKS cluster deployed in the application spoke subscription.
# Dependencies:
#   - baseline stack: spoke_vnet_id, key_vault_id, managed_identity_id, resource_group_name, aks_subnet_id
#   - management stack: log_analytics_workspace_id
# Provider alias "azurerm.workload" is injected by terragrunt via provider_generated.tf.

# ---------------------------------------------------------------------------
# Outputs consumed by downstream stacks (via terragrunt dependency blocks):
#   - aks_cluster_id   : Resource ID of the AKS cluster (from outputs.tf)
#   - aks_cluster_name : Name of the AKS cluster, e.g. "{name_prefix}-{environment}-aks"
#   - aks_node_resource_group : Auto-generated MC_* node resource group name
# Any stack that needs the cluster ID or name should declare:
#   dependency "aks" { config_path = "../workloads/aks" }
#   and reference dependency.aks.outputs.aks_cluster_id / aks_cluster_name.
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

module "aks" {
  source = "../../../../modules/aks"

  providers = {
    azurerm = azurerm.workload
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = var.resource_group_name

  log_analytics_workspace_id = var.log_analytics_workspace_id

  # R6: VNet integration — nodes are placed into the spoke AKS subnet from baseline stack.
  # When aks_subnet_id is null (e.g. older environments without baseline output), AKS uses
  # its default managed VNet — backward compatible.
  subnet_id = var.aks_subnet_id

  # TODO: Pass managed_identity_id for workload identity (requires modules/aks to add identity block)
  # TODO: Pass key_vault_id for CSI secrets driver (requires modules/aks to add key_vault_secrets_provider add-on)
  # Track: https://github.com/your-org/infra/issues/XX

  tags = local.mandatory_tags
}

# R8: Diagnostic Settings — AKS cluster logs to central Log Analytics workspace
module "aks_diagnostics" {
  source = "../../../../modules/diagnostic-settings"
  count  = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  name                       = "${var.name_prefix}-${var.environment}-aks-diag"
  target_resource_id         = module.aks.aks_cluster_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log_categories = [
    "kube-apiserver",
    "kube-controller-manager",
    "kube-scheduler",
    "kube-audit",
    "kube-audit-admin",
    "guard",
    "cluster-autoscaler",
  ]

  metric_categories = ["AllMetrics"]
}
