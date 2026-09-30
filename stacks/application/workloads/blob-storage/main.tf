locals {
  mandatory_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# The shared module enforces HTTPS, TLS 1.2, and disables anonymous blob
# access. AKS is granted access through its managed identity, not an account key.
module "blob_storage" {
  source = "../../../../modules/storage-account"

  providers = {
    azurerm = azurerm.workload
  }

  name_prefix                = var.name_prefix
  environment                = var.environment
  resource_group_name        = var.resource_group_name
  location                   = var.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  enable_versioning          = true
  soft_delete_retention_days = 30

  containers = {
    application-data = {
      access_type = "private"
    }
  }

  tags = local.mandatory_tags
}

# Blob CSI mounts and other node-identity based access from AKS use this
# data-plane role. No storage account key is exposed to the cluster.
resource "azurerm_role_assignment" "aks_blob_data_contributor" {
  provider             = azurerm.workload
  scope                = module.blob_storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.aks_kubelet_identity_object_id
}

# Storage logs are configured on the Blob service child resource rather than
# the parent storage account.
module "blob_storage_diagnostics" {
  source = "../../../../modules/diagnostic-settings"
  count  = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  name                       = "${var.name_prefix}-${var.environment}-blob-diag"
  target_resource_id         = "${module.blob_storage.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = ["StorageRead", "StorageWrite", "StorageDelete"]
  # Preserve every metric category already enabled on the existing setting.
  metric_categories = ["Transaction", "Capacity"]
}

# Import is opt-in so a new environment does not try to adopt a resource that
# does not exist yet. IDs are derived from the deployed storage account and
# naming inputs, not from Thanh-specific values.
import {
  for_each = var.adopt_existing_diagnostic_setting ? toset(["existing"]) : toset([])
  to       = module.blob_storage_diagnostics[0].azurerm_monitor_diagnostic_setting.this
  id       = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${substr(lower("${var.name_prefix}${var.environment}st"), 0, 24)}/blobServices/default|${var.name_prefix}-${var.environment}-blob-diag"
}
