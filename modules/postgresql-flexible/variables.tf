# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to produce the server name."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the PostgreSQL Flexible Server."
  type        = string
}

variable "location" {
  description = "Azure region for the PostgreSQL Flexible Server (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Server compute & storage
# ---------------------------------------------------------------------------

variable "sku_name" {
  description = "SKU name determining the compute tier and size. Examples: 'B_Standard_B1ms' (Burstable), 'GP_Standard_D2s_v3' (General Purpose)."
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL major version. Allowed values: '11', '12', '13', '14', '15', '16'."
  type        = string
  default     = "16"
}

variable "storage_mb" {
  description = "Maximum storage in megabytes allocated to the server. Must be a multiple of 1024. Default is 32 GiB (32768 MB)."
  type        = number
  default     = 32768
}

# ---------------------------------------------------------------------------
# Administrator credentials
# ---------------------------------------------------------------------------

variable "admin_username" {
  description = "Administrator login name for the PostgreSQL Flexible Server."
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the PostgreSQL Flexible Server. Mark sensitive — store value in Key Vault and pass via data source or variable injection."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------

variable "backup_retention_days" {
  description = "Number of days to retain automated backups. Allowed range: 7–35."
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups to pair region. Requires General Purpose or Memory Optimized SKU."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# High availability (optional)
# ---------------------------------------------------------------------------

variable "high_availability_mode" {
  description = "High availability mode. Set to 'SameZone' for same-zone standby or 'ZoneRedundant' for cross-zone standby. Null disables HA."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Networking — private access
# ---------------------------------------------------------------------------

variable "delegated_subnet_id" {
  description = "Resource ID of the subnet delegated to 'Microsoft.DBforPostgreSQL/flexibleServers'. Required for VNet-injected (private) deployment."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone used for VNet-injected deployment (e.g. 'privatelink.postgres.database.azure.com')."
  type        = string
}

# ---------------------------------------------------------------------------
# Databases
# ---------------------------------------------------------------------------

variable "databases" {
  description = "Map of databases to create on the server. Key = database name. charset example: 'UTF8', collation example: 'en_US.utf8'."
  type = map(object({
    charset   = string
    collation = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Customer-managed key (optional)
# ---------------------------------------------------------------------------

variable "key_vault_key_id" {
  description = "Resource ID of the Key Vault key to use for customer-managed encryption (CMK). When null, service-managed keys are used."
  type        = string
  default     = null
}
