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
# Data sources
# ---------------------------------------------------------------------------

# Look up the resource group that owns the spoke VNet so we can place the
# Private DNS zone in the same resource group.
data "azurerm_virtual_network" "spoke" {
  provider            = azurerm.workload
  name                = "${var.name_prefix}-${var.environment}-vnet"
  resource_group_name = var.resource_group_name
}

# The "data" subnet carries the PostgreSQL flexibleServers delegation.
# Its name is "data" as defined in app_subnets inside env.hcl.
data "azurerm_subnet" "postgresql" {
  provider             = azurerm.workload
  name                 = "data"
  virtual_network_name = data.azurerm_virtual_network.spoke.name
  resource_group_name  = data.azurerm_virtual_network.spoke.resource_group_name
}

# ---------------------------------------------------------------------------
# Private DNS Zone for PostgreSQL Flexible Server
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgresql" {
  provider            = azurerm.workload
  name                = "${var.name_prefix}-${var.environment}-psql.private.postgres.database.azure.com"
  resource_group_name = data.azurerm_virtual_network.spoke.resource_group_name

  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  provider              = azurerm.workload
  name                  = "${var.name_prefix}-${var.environment}-psql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = var.spoke_vnet_id
  resource_group_name   = data.azurerm_virtual_network.spoke.resource_group_name
  registration_enabled  = false

  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

# Store the private PostgreSQL connection URL in the baseline Key Vault. The
# password remains sensitive and is URL-encoded for URI safety.
resource "azurerm_key_vault_secret" "postgresql_connection_url" {
  provider     = azurerm.workload
  name         = "postgresql-connection-url"
  value        = "postgresql://psqladmin:${urlencode(var.postgresql_admin_password)}@${module.postgresql.server_fqdn}:5432/postgres?sslmode=require"
  key_vault_id = var.key_vault_id
  content_type = "application/vnd.postgresql.connection-string"

  depends_on = [module.postgresql]
}

# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server
# ---------------------------------------------------------------------------

module "postgresql" {
  source = "../../../../modules/postgresql-flexible"

  providers = {
    azurerm = azurerm.workload
  }

  # Naming: <name_prefix>-<environment>-psql  (R15.2, R15.3)
  name_prefix = var.name_prefix
  environment = "${var.environment}-psql"

  resource_group_name = data.azurerm_virtual_network.spoke.resource_group_name
  location            = var.location

  # Compute & storage — suitable defaults for non-prod; override via tfvars for prod
  sku_name           = "B_Standard_B1ms"
  postgresql_version = "16"
  storage_mb         = 32768

  # Administrator credentials — pass via environment variables or CI secrets,
  # never hardcoded. Values expected as Terragrunt inputs injected at runtime.
  admin_username = "psqladmin"
  admin_password = var.postgresql_admin_password

  # Backup
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # Private networking — delegate the "data" subnet (R9.7)
  # Subnet must have the Microsoft.DBforPostgreSQL/flexibleServers delegation
  # configured in env.hcl app_subnets.data.delegation
  delegated_subnet_id = data.azurerm_subnet.postgresql.id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql.id

  # Mandatory tags (R9.10, R9.12)
  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# R8: Diagnostic Settings — gửi PostgreSQL logs về Log Analytics workspace
# ---------------------------------------------------------------------------

module "postgresql_diagnostics" {
  source = "../../../../modules/diagnostic-settings"
  count  = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  name                       = "${var.name_prefix}-${var.environment}-psql-diag"
  target_resource_id         = module.postgresql.server_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log_categories = [
    "PostgreSQLLogs",
    "QueryStoreRuntimeStatistics",
    "QueryStoreWaitStatistics",
  ]

  metric_categories = ["AllMetrics"]
}
