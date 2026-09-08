terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_storage_account" "this" {
  name                = substr(lower("${var.name_prefix}${var.environment}st"), 0, 24)
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Security defaults — hardcoded, non-negotiable
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  dynamic "blob_properties" {
    for_each = (var.enable_versioning || var.soft_delete_retention_days > 0) ? [1] : []

    content {
      versioning_enabled = var.enable_versioning

      dynamic "delete_retention_policy" {
        for_each = var.soft_delete_retention_days > 0 ? [1] : []
        content {
          days = var.soft_delete_retention_days
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.customer_managed_key_id != null ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.access_type
}

# Note: azurerm_storage_management_policy (for lifecycle_rules) is intentionally
# omitted from this module. The lifecycle_rules variable is declared in variables.tf
# but the policy resource should be created at the consumer level, referencing
# this module's storage_account_id output — avoids dependency ordering issues.
