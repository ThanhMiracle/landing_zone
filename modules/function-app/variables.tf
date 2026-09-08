# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to form resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the Function App and Service Plan."
  type        = string
}

variable "location" {
  description = "Azure region for the resources (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Service Plan
# ---------------------------------------------------------------------------

variable "service_plan_sku" {
  description = "SKU name for the App Service Plan. 'Y1' = Consumption (serverless), 'EP1'/'EP2'/'EP3' = Elastic Premium."
  type        = string
  default     = "Y1"
}

# ---------------------------------------------------------------------------
# Runtime stack
# ---------------------------------------------------------------------------

variable "runtime_stack" {
  description = "Runtime stack for the Function App. name must be one of: python, node, dotnet, java. version is the runtime version string (e.g. '3.11', '20', '8.0', '17')."
  type = object({
    name    = string
    version = string
  })
}

# ---------------------------------------------------------------------------
# Storage account (required by Function App for its internal operations)
# ---------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Name of the Storage Account used by the Function App for host state, logs, and trigger metadata."
  type        = string
}

variable "storage_account_connection_string" {
  description = "Connection string for the Storage Account used by the Function App for host state, logs, and trigger metadata."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Application settings
# ---------------------------------------------------------------------------

variable "app_settings" {
  description = "Map of application settings (environment variables) passed to the Function App. Merged with internally required settings."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networking — optional VNet integration
# ---------------------------------------------------------------------------

variable "vnet_integration_subnet_id" {
  description = "Resource ID of the subnet to integrate the Function App with for outbound VNet traffic. Requires a delegation to 'Microsoft.Web/serverFarms'. When null, VNet integration is disabled."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Key Vault reference identity (optional)
# ---------------------------------------------------------------------------

variable "key_vault_reference_identity_id" {
  description = "Resource ID of a user-assigned Managed Identity used to resolve Key Vault references in app settings. When null, the system-assigned identity is used."
  type        = string
  default     = null
}
