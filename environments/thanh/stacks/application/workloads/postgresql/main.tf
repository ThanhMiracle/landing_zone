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
# This metadata-only data source returns secret IDs, names, tags, and enabled
# status. It does not return secret values. It is evaluated only when adopting
# resources that already exist outside Terraform state.
data "azurerm_key_vault_secrets" "existing" {
  count    = var.adopt_existing_resources ? 1 : 0
  provider = azurerm.workload

  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "postgresql_connection_url" {
  provider     = azurerm.workload
  name         = "postgresql-connection-url"
  value        = "postgresql://psqladmin:${urlencode(var.postgresql_admin_password)}@${module.postgresql.server_fqdn}:5432/postgres?sslmode=require"
  key_vault_id = var.key_vault_id
  content_type = "application/vnd.postgresql.connection-string"

  depends_on = [module.postgresql]
}

# Import the current version of a pre-existing secret. A fresh environment
# leaves adoption disabled and creates the secret normally. Terraform obtains
# the versioned ID from Key Vault metadata, so no environment-specific ID is
# committed or injected through the pipeline.
import {
  for_each = var.adopt_existing_resources ? toset([
    for secret in data.azurerm_key_vault_secrets.existing[0].secrets : secret.id
    if secret.name == "postgresql-connection-url"
  ]) : toset([])

  to = azurerm_key_vault_secret.postgresql_connection_url
  id = each.value
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
  # Use the four-vCore Burstable SKU available in Japan West instead of the
  # previously capacity-constrained B1ms size.
  sku_name           = "B_Standard_B4ms"
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
    "PostgreSQLFlexSessions",
    "PostgreSQLFlexTableStats",
    "PostgreSQLFlexDatabaseXacts",
    "PostgreSQLFlexPGBouncer",
    "PostgreSQLQueryStoreSqlText",
  ]

  metric_categories = [
    "AllMetrics"
  ]
}

# Import is opt-in so a new environment does not try to adopt a resource that
# does not exist yet. IDs are derived from normal stack inputs, not Thanh
# specific values.
import {
  for_each = var.adopt_existing_resources ? toset(["existing"]) : toset([])
  to       = module.postgresql_diagnostics[0].azurerm_monitor_diagnostic_setting.this
  id       = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${var.name_prefix}-${var.environment}-psql|${var.name_prefix}-${var.environment}-psql-diag"
}
