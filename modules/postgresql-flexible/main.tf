terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "${var.name_prefix}-${var.environment}-psql"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name   = var.sku_name
  version    = var.postgresql_version
  storage_mb = var.storage_mb

  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Private access via delegated subnet — no public access by default
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false

  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [var.high_availability_mode] : []
    content {
      mode = high_availability.value
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.key_vault_key_id != null ? [var.key_vault_key_id] : []
    content {
      key_vault_key_id = customer_managed_key.value
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

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = var.databases

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = each.value.charset
  collation = each.value.collation
}
