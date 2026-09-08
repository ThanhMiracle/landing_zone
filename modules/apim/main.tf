terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# API Management
# ---------------------------------------------------------------------------
resource "azurerm_api_management" "this" {
  name                = "${var.name_prefix}-${var.environment}-apim"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name        = var.sku_name
  publisher_name  = var.publisher_name
  publisher_email = var.publisher_email

  identity {
    type = "SystemAssigned"
  }

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != null ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  virtual_network_type = var.virtual_network_type != null ? var.virtual_network_type : "None"

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
