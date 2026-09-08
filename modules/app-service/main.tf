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
# azurerm_linux_web_app application_stack uses separate version attributes
# per runtime: python_version, node_version, dotnet_version, java_version,
# php_version, ruby_version. Only the relevant one should be set; others
# remain null and are omitted by the provider.
# ---------------------------------------------------------------------------

locals {
  python_version = var.runtime_stack.name == "python" ? var.runtime_stack.version : null
  node_version   = var.runtime_stack.name == "node" ? var.runtime_stack.version : null
  dotnet_version = var.runtime_stack.name == "dotnet" ? var.runtime_stack.version : null
  java_version   = var.runtime_stack.name == "java" ? var.runtime_stack.version : null
  php_version    = var.runtime_stack.name == "php" ? var.runtime_stack.version : null

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
# Service Plan — hosts the Web App
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
# Linux Web App
# ---------------------------------------------------------------------------

resource "azurerm_linux_web_app" "this" {
  name                = "${var.name_prefix}-${var.environment}-app"
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id = azurerm_service_plan.this.id

  # System-assigned Managed Identity — required by R10
  identity {
    type = "SystemAssigned"
  }

  # Application settings
  app_settings = var.app_settings

  # Optional: VNet integration for outbound traffic
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  site_config {
    application_stack {
      python_version = local.python_version
      node_version   = local.node_version
      dotnet_version = local.dotnet_version
      java_version   = local.java_version
      php_version    = local.php_version
    }
  }

  tags = local.common_tags
}
