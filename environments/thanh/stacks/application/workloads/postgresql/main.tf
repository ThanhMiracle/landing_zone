# =============================================================================
# infra/stacks/application/workloads/postgresql/main.tf
#
# Deploys a PostgreSQL Flexible Server (VNet-injected, private access) into
# the spoke network created by the application/baseline stack.
#
# Subnet delegation: the "data" subnet in app_subnets must carry the
# Microsoft.DBforPostgreSQL/flexibleServers delegation (configured in env.hcl).
#
# Requirements: R9.2, R9.7, R9.10, R9.12, R13.5–R13.7, R15.2, R15.3
# =============================================================================

# ---------------------------------------------------------------------------
# Private DNS Zone for PostgreSQL Flexible Server
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgresql" {
  provider            = azurerm.workload
  name                = "${var.name_prefix}-${var.environment}-psql.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  provider              = azurerm.workload
  name                  = "${var.name_prefix}-${var.environment}-psql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = var.spoke_vnet_id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false

  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Store the private PostgreSQL connection URL in Key Vault. URL encoding keeps
# password characters valid inside the URI.
resource "azurerm_key_vault_secret" "postgresql_connection_url" {
  provider     = azurerm.workload
  name         = "postgresql-connection-url"
  value        = "postgresql://psqladmin:${urlencode(var.postgresql_admin_password)}@${module.postgresql.server_fqdn}:5432/postgres?sslmode=require"
  key_vault_id = var.key_vault_id
  content_type = "application/vnd.postgresql.connection-string"

  depends_on = [module.postgresql]
}

# PostgreSQL Flexible Server
# ---------------------------------------------------------------------------

module "postgresql" {
  source = "../../../../modules/postgresql-flexible"

  providers = {
    azurerm = azurerm.workload
  }

  # The module appends -psql itself; passing the plain environment prevents
  # an accidental duplicate suffix such as ...-dev-psql-psql.
  name_prefix = var.name_prefix
  environment = var.environment

  resource_group_name = var.resource_group_name
  location            = var.location

  # Compute & storage
  # Japan West advertises B2s as the default Burstable Flexible Server SKU.
  # It provides two vCores and avoids retrying the capacity-constrained B1ms.
  sku_name           = "B_Standard_B2s"
  postgresql_version = "16"
  storage_mb         = 32768

  # Administrator credentials
  admin_username = "psqladmin"
  admin_password = var.postgresql_admin_password

  # Backup
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # Private networking
  delegated_subnet_id = var.data_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql.id

  # Mandatory tags
  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Diagnostic Settings
# ---------------------------------------------------------------------------

module "postgresql_diagnostics" {
  source = "../../../../modules/diagnostic-settings"

  count = (
    var.log_analytics_workspace_id != null &&
    var.log_analytics_workspace_id != ""
  ) ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  name                       = "${var.name_prefix}-${var.environment}-psql-diag"
  target_resource_id         = module.postgresql.server_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log_categories = [
    "PostgreSQLLogs",
    "PostgreSQLFlexQueryStoreRuntime",
    "PostgreSQLFlexQueryStoreWaitStats",
  ]

  metric_categories = [
    "AllMetrics"
  ]
}
