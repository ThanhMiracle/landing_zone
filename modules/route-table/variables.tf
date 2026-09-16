variable "name_prefix" {
  description = "Prefix for route table resource name."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod, connectivity)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the route table into."
  type        = string
}

variable "location" {
  description = "Azure region for the route table."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge into all resources."
  type        = map(string)
  default     = {}
}

variable "bgp_route_propagation_enabled" {
  description = "Whether to enable BGP route propagation on the route table. Default false prevents on-premises routes from overriding User Defined Routes."
  type        = bool
  default     = false
}

variable "routes" {
  description = "Map of routes to create. Each key becomes the route resource name. Use next_hop_in_ip_address when next_hop_type = 'VirtualAppliance'."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
}

variable "subnet_ids" {
  description = "Map of stable subnet names to subnet resource IDs to associate with this route table. All listed subnets will share the same route table."
  type        = map(string)
}
