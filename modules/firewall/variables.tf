variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment, e.g. 'dev', 'prod', 'connectivity'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where firewall resources will be created"
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
  description = "Resource ID of the AzureFirewallSubnet (must be named exactly 'AzureFirewallSubnet', minimum /26 prefix)"
  type        = string
}

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier. Allowed values: 'Standard' or 'Premium'"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be either 'Standard' or 'Premium'."
  }
}

variable "rule_collection_group_priority" {
  description = "Priority for the Firewall Policy Rule Collection Group. Must be between 100 and 65000"
  type        = number
  default     = 100
}

variable "network_rule_collections" {
  description = <<-EOT
    Map of network rule collections to create inside the rule collection group.
    Empty map (default) creates no network rule collections.

    Each key becomes the rule collection name. Each object supports:
      - priority  (required) number       — priority within the group (100–65000)
      - action    (required) string       — "Allow" or "Deny"
      - rules     (required) list(object) — list of network rules, each with:
          - name                  string        — rule name
          - protocols             list(string)  — e.g. ["TCP", "UDP", "ICMP", "Any"]
          - source_addresses      list(string)  — source IP ranges or tags
          - destination_addresses list(string)  — destination IP ranges or tags
          - destination_ports     list(string)  — destination port ranges
  EOT
  type = map(object({
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
    }))
  }))
  default = {}
}

variable "application_rule_collections" {
  description = <<-EOT
    Map of application rule collections to create inside the rule collection group.
    Empty map (default) creates no application rule collections.

    Each key becomes the rule collection name. Each object supports:
      - priority  (required) number       — priority within the group (100–65000)
      - action    (required) string       — "Allow" or "Deny"
      - rules     (required) list(object) — list of application rules, each with:
          - name             string        — rule name
          - source_addresses list(string)  — source IP ranges or tags
          - protocols        list(object)  — each with type (string) and port (number)
          - destination_fqdns list(string)  — destination FQDNs
  EOT
  type = map(object({
    priority = number
    action   = string
    rules = list(object({
      name             = string
      source_addresses = list(string)
      protocols = list(object({
        type = string
        port = number
      }))
      destination_fqdns     = optional(list(string), [])
      destination_fqdn_tags = optional(list(string), [])
    }))
  }))
  default = {}
}

variable "dnat_rule_collections" {
  description = <<-EOT
    Map of DNAT rule collections to create inside the rule collection group.
    Empty map (default) creates no DNAT rule collections.

    Each key becomes the rule collection name. Each object supports:
      - priority  (required) number       — priority within the group (100–65000)
      - action    (required) string       — must be "Dnat"
      - rules     (required) list(object) — list of DNAT rules, each with:
          - name                  string        — rule name
          - protocols             list(string)  — e.g. ["TCP", "UDP"]
          - source_addresses      list(string)  — source IP ranges
          - destination_address   string        — the firewall public IP
          - destination_ports     list(string)  — inbound ports
          - translated_address    string        — target internal IP
          - translated_port       string        — target internal port
  EOT
  type = map(object({
    priority = number
    action   = string
    rules = list(object({
      name                = string
      protocols           = list(string)
      source_addresses    = list(string)
      destination_address = optional(string)
      destination_ports   = list(string)
      translated_address  = string
      translated_port     = string
    }))
  }))
  default = {}
}
