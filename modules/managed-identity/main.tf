terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name_prefix}-${var.environment}-id"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
