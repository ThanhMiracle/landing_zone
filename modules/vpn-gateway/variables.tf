variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment, e.g. 'dev', 'prod', 'connectivity'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where VPN Gateway resources will be created"
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

variable "gateway_subnet_id" {
  description = "Resource ID of the GatewaySubnet (must be named exactly 'GatewaySubnet', minimum /27 prefix)"
  type        = string
}

variable "sku" {
  description = "SKU of the VPN Gateway. Allowed values: 'Basic', 'VpnGw1', 'VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'"
  type        = string
  default     = "VpnGw1"

  validation {
    condition     = contains(["Basic", "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5"], var.sku)
    error_message = "sku must be one of: 'Basic', 'VpnGw1', 'VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'."
  }
}

variable "vpn_connections" {
  description = <<-EOT
    Map of site-to-site VPN connections to create. Empty map (default) creates no connection resources.

    Each key becomes the connection identifier used in resource names ({name_prefix}-{environment}-conn-{key}).
    Each object supports:
      - local_gateway_address  (required) string        — public IP of the on-premises VPN device
      - shared_key             (required) string        — pre-shared key (PSK) for the IPsec tunnel; treated as sensitive
      - address_spaces         (required) list(string)  — on-premises CIDR address ranges reachable via this connection
  EOT
  type = map(object({
    local_gateway_address = string
    shared_key            = string
    address_spaces        = list(string)
  }))
  default = {}
}
