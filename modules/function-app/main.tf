terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Locals — resolve runtime stack fields
#
# azurerm_linux_function_app application_stack uses separate version attributes
# per runtime: python_version, node_version, dotnet_version, java_version.
# Only the relevant one should be set; others are omitted via null.
# ---------------------------------------------------------------------------

locals {
  python_version = var.runtime_stack.name == "python" ? var.runtime_stack.version : null
  node_version   = var.runtime_stack.name == "node" ? var.runtime_stack.version : null
  dotnet_version = var.runtime_stack.name == "dotnet" ? var.runtime_stack.version : null
  java_version   = var.runtime_stack.name == "java" ? var.runtime_stack.version : null

  common_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------
# Service Plan — hosts the Function App
# SKU "Y1" = Consumption (serverless), "EP1"/"EP2"/"EP3" = Elastic Premium
# ---------------------------------------------------------------------------

resource "azurerm_service_plan" "this" {
  name                = "${var.name_prefix}-${var.environment}-asp"
  resource_group_name = var.resource_group_name
  location            = var.location

  os_type  = "Linux"
  sku_name = var.service_plan_sku

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Linux Function App
# ---------------------------------------------------------------------------

resource "azurerm_linux_function_app" "this" {
  name                = "${var.name_prefix}-${var.environment}-func"
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_connection_string

  # System-assigned Managed Identity — required by R10
  identity {
    type = "SystemAssigned"
  }

  # Application settings — merged with any caller-supplied values
  app_settings = var.app_settings

  # Optional: Key Vault reference identity (user-assigned MI for KV references)
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Optional: VNet integration
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  site_config {
    application_stack {
      python_version = local.python_version
      node_version   = local.node_version
      dotnet_version = local.dotnet_version
      java_version   = local.java_version
    }
  }

  tags = local.common_tags
}
