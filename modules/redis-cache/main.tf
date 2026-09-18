terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_redis_cache" "this" {
  name                = "${var.name_prefix}-${var.environment}-redis"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name = var.sku_name
  family   = var.sku_name == "Premium" ? "P" : (var.sku_name == "Standard" ? "C" : "C")
  capacity = var.capacity

  redis_version        = var.redis_version
  minimum_tls_version  = "1.2"
  non_ssl_port_enabled = false

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
