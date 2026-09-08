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

variable "address_space" {
  description = "List of CIDR blocks for the Virtual Network address space, e.g. ['10.0.0.0/16']"
  type        = list(string)
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create inside the VNet. Each key is used as the subnet name.

    Each subnet object supports:
      - address_prefixes    (required) list(string) — CIDR block(s) for the subnet
      - service_endpoints   (optional) list(string) — e.g. ["Microsoft.Storage", "Microsoft.KeyVault"]
      - delegation          (optional) object — enables service delegation on the subnet
          - name                         string  — delegation resource name, e.g. "delegation"
          - service_delegation:
              - name    string        — service name, e.g. "Microsoft.DBforPostgreSQL/flexibleServers"
              - actions list(string)  — allowed actions, e.g. ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  EOT
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    }))
  }))
}
