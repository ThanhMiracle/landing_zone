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

variable "subnet_id" {
  description = "Resource ID of the subnet to associate the NSG with"
  type        = string
}

variable "security_rules" {
  description = <<-EOT
    Map of security rules to create on the NSG. Each key is used as the rule name.

    Each rule object supports:
      - priority                   (required) number  — rule priority, 100–4096 (lower = higher priority)
      - direction                  (required) string  — "Inbound" or "Outbound"
      - access                     (required) string  — "Allow" or "Deny"
      - protocol                   (required) string  — "Tcp", "Udp", "Icmp", "Esp", "Ah", or "*"
      - source_port_range          (required) string  — source port or range, e.g. "*", "443", "1024-65535"
      - destination_port_range     (required) string  — destination port or range, e.g. "80", "443"
      - source_address_prefix      (required) string  — source CIDR or tag, e.g. "10.0.0.0/8", "Internet"
      - destination_address_prefix (required) string  — destination CIDR or tag, e.g. "VirtualNetwork", "*"
  EOT
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {}
}
