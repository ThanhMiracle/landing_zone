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
  description = "Name of the Azure Resource Group in which to create the App Service and Service Plan."
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
  description = "SKU name for the App Service Plan (e.g. 'B1' = Basic, 'S1' = Standard, 'P1v3' = Premium v3)."
  type        = string
  default     = "B1"
}

# ---------------------------------------------------------------------------
# Runtime stack
# ---------------------------------------------------------------------------

variable "runtime_stack" {
  description = "Runtime stack for the Web App. name must be one of: python, node, dotnet, java, php, ruby. version is the runtime version string (e.g. '3.11', '20', '8.0', '17', '8.2', '3.2')."
  type = object({
    name    = string
    version = string
  })
}

# ---------------------------------------------------------------------------
# Application settings
# ---------------------------------------------------------------------------

variable "app_settings" {
  description = "Map of application settings (environment variables) passed to the Web App."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networking — optional VNet integration
# ---------------------------------------------------------------------------

variable "vnet_integration_subnet_id" {
  description = "Resource ID of the subnet to integrate the Web App with for outbound VNet traffic. Requires a delegation to 'Microsoft.Web/serverFarms'. When null, VNet integration is disabled."
  type        = string
  default     = null
}
