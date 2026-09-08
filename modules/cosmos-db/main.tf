terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_cosmosdb_account" "this" {
  name                = "${var.name_prefix}-${var.environment}-cosmos"
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  automatic_failover_enabled = var.enable_automatic_failover

  is_virtual_network_filter_enabled = var.enable_virtual_network_filter
  public_network_access_enabled     = var.public_network_access_enabled

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? var.bounded_staleness_max_interval : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? var.bounded_staleness_max_prefix : null
  }

  # Primary geo-location (failover priority 0)
  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Additional geo-locations for replication
  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
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

resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name

  throughput = each.value.throughput
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = var.containers

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this[each.value.database_name].name

  partition_key_paths = [each.value.partition_key_path]

  throughput = each.value.throughput
}
