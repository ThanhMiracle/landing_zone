# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to produce the account name."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the Cosmos DB account."
  type        = string
}

variable "location" {
  description = "Primary Azure region for the Cosmos DB account (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Consistency
# ---------------------------------------------------------------------------

variable "consistency_level" {
  description = "Default consistency level for the Cosmos DB account. Allowed values: 'Eventual', 'ConsistentPrefix', 'Session', 'BoundedStaleness', 'Strong'."
  type        = string
  default     = "Session"

  validation {
    condition     = contains(["Eventual", "ConsistentPrefix", "Session", "BoundedStaleness", "Strong"], var.consistency_level)
    error_message = "consistency_level must be one of: Eventual, ConsistentPrefix, Session, BoundedStaleness, Strong."
  }
}

# ---------------------------------------------------------------------------
# Failover & geo-replication
# ---------------------------------------------------------------------------

variable "enable_automatic_failover" {
  description = "Enable automatic failover for the Cosmos DB account. When true, the service can automatically fail over to a secondary region."
  type        = bool
  default     = false
}

variable "geo_locations" {
  description = "Map of additional geo-locations to replicate data to. Key = logical name, value = object with location (Azure region) and failover_priority (must be > 0, unique per account)."
  type = map(object({
    location          = string
    failover_priority = number
  }))
  default = {}
}

variable "bounded_staleness_max_interval" {
  description = "Max staleness interval in seconds (only for BoundedStaleness consistency)"
  type        = number
  default     = 300
}

variable "bounded_staleness_max_prefix" {
  description = "Max staleness prefix (only for BoundedStaleness consistency)"
  type        = number
  default     = 100000
}

# ---------------------------------------------------------------------------
# Databases
# ---------------------------------------------------------------------------

variable "databases" {
  description = "Map of SQL databases to create inside the Cosmos DB account. Key = database name. throughput: optional manual throughput in RU/s; omit to use serverless/shared."
  type = map(object({
    throughput = optional(number, null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Containers
# ---------------------------------------------------------------------------

variable "containers" {
  description = "Map of SQL containers to create. Key = container name. database_name must match a key in var.databases. partition_key_path is required (e.g. '/id'). throughput: optional manual throughput in RU/s."
  type = map(object({
    database_name      = string
    partition_key_path = string
    throughput         = optional(number, null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Network access controls
# ---------------------------------------------------------------------------

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Cosmos DB account. Set to false for production."
  type        = bool
  default     = false
}

variable "enable_virtual_network_filter" {
  description = "Whether to enable the virtual network filter for this Cosmos DB account."
  type        = bool
  default     = false
}
