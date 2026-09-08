# ─── Standard module inputs ───────────────────────────────────────────────────

variable "name_prefix" {
  type        = string
  description = "Prefix used in all resource names, e.g. 'myproject'."
}

variable "environment" {
  type        = string
  description = "Environment label, e.g. 'connectivity', 'dev', 'prod'."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the DNS Resolver into."
}

variable "location" {
  type        = string
  description = "Azure region for all resources in this module."
  default     = "southeastasia"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged with mandatory Project/Environment/ManagedBy tags."
  default     = {}
}

# ─── DNS Resolver-specific inputs ─────────────────────────────────────────────

variable "vnet_id" {
  type        = string
  description = "Resource ID of the hub VNet where the Private DNS Resolver is deployed."
}

variable "inbound_subnet_id" {
  type        = string
  description = "Resource ID of the dedicated inbound subnet (minimum /28 prefix required by Azure)."
}

variable "outbound_subnet_id" {
  type        = string
  description = "Resource ID of the outbound subnet. When non-empty, an outbound endpoint is created to enable DNS forwarding to external servers."
  default     = ""
}

variable "dns_forwarding_rulesets" {
  type        = map(object({}))
  description = "Map of DNS forwarding ruleset definitions. Each key becomes the ruleset name. When non-empty, requires outbound_subnet_id to be set. Currently accepts empty objects; extend the object schema as forwarding rules are added."
  default     = {}
}
