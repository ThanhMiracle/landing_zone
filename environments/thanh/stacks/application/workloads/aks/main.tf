# infra/stacks/application/workloads/aks/main.tf
# Workload template: AKS cluster deployed in the application spoke subscription.
# Dependencies:
#   - baseline stack: Key Vault, control-plane identity, resource group, AKS subnet, and ACR
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
  identity_id         = var.managed_identity_id
  outbound_type       = var.outbound_type

  log_analytics_workspace_id = var.log_analytics_workspace_id

  # R6: VNet integration — nodes are placed into the spoke AKS subnet from baseline stack.
  # When aks_subnet_id is null (e.g. older environments without baseline output), AKS uses
  # its default managed VNet — backward compatible.
  subnet_id = var.aks_subnet_id

  tags = local.mandatory_tags

  depends_on = [
    azurerm_role_assignment.aks_subnet_network_contributor,
    azurerm_role_assignment.aks_route_table_network_contributor,
  ]
}

# The user-assigned control-plane identity must be able to manage networking
# in the pre-created AKS subnet before the cluster is provisioned.
resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  provider                         = azurerm.workload
  scope                            = var.aks_subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = var.managed_identity_principal_id
  skip_service_principal_aad_check = true
}

# AKS must be able to maintain its custom route table when UDR is enabled.
resource "azurerm_role_assignment" "aks_route_table_network_contributor" {
  count = var.aks_route_table_id == null ? 0 : 1

  provider                         = azurerm.workload
  scope                            = var.aks_route_table_id
  role_definition_name             = "Network Contributor"
  principal_id                     = var.managed_identity_principal_id
  skip_service_principal_aad_check = true
}

# Nodes pull workload images from the baseline Azure Container Registry.
resource "azurerm_role_assignment" "aks_acr_pull" {
  provider                         = azurerm.workload
  scope                            = var.container_registry_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

# R8: Diagnostic Settings — AKS cluster logs to central Log Analytics workspace
# The Key Vault CSI add-on identity reads secrets from the application vault.
resource "azurerm_role_assignment" "key_vault_secrets_provider" {
  provider             = azurerm.workload
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.key_vault_secrets_provider_object_id
}

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
