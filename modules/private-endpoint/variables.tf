variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment, e.g. 'dev', 'prod'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for all resources in this module"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory tags (Project, Environment, ManagedBy)"
  type        = map(string)
  default     = {}
}

variable "resource_id" {
  description = "Resource ID of the target Azure resource to connect via private endpoint"
  type        = string
}

variable "subresource_names" {
  description = "List of subresource names for the private service connection, e.g. [\"vault\"], [\"blob\"], [\"postgresqlServer\"]"
  type        = list(string)
}

variable "subnet_id" {
  description = "Resource ID of the subnet in which the private endpoint will be created"
  type        = string
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone for the target service, e.g. 'privatelink.vaultcore.azure.net', 'privatelink.blob.core.windows.net'"
  type        = string
}

variable "create_dns_zone" {
  description = "Whether to create a new private DNS zone. Set to false if the zone already exists and you want to reuse it."
  type        = bool
  default     = false
}

variable "vnet_id" {
  description = "Resource ID of the Virtual Network to link with the private DNS zone. Required when create_dns_zone = true."
  type        = string
  default     = ""
}
