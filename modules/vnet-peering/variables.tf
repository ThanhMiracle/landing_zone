variable "name_prefix" {
  description = "Prefix for peering resource names."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod, connectivity)."
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.hub_vnet_id))
    error_message = "hub_vnet_id must be a valid Azure VNet resource ID."
  }
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.spoke_vnet_id))
    error_message = "spoke_vnet_id must be a valid Azure VNet resource ID."
  }
}

variable "hub_resource_group_name" {
  description = "Name of the resource group containing the hub VNet."
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Name of the resource group containing the spoke VNet."
  type        = string
}

variable "allow_gateway_transit" {
  description = "When true: hub-to-spoke peering sets allow_gateway_transit = true and spoke-to-hub sets use_remote_gateways = true. Enables VPN/ExpressRoute pass-through from spoke to hub gateway."
  type        = bool
  default     = false
}
