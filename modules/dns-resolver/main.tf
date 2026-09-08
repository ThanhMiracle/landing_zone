terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  mandatory_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ─── Private DNS Resolver ─────────────────────────────────────────────────────

resource "azurerm_private_dns_resolver" "this" {
  name                = "${var.name_prefix}-${var.environment}-dnsresolver"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = var.vnet_id

  tags = local.mandatory_tags
}

# ─── Inbound Endpoint (always created) ───────────────────────────────────────
# Requires a dedicated subnet with minimum /28 prefix (Azure restriction).
# The private IP assigned here is what spoke VNets configure as their DNS server.

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  name                    = "${var.name_prefix}-${var.environment}-dnsresolver-inbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location

  ip_configurations {
    subnet_id                    = var.inbound_subnet_id
    private_ip_allocation_method = "Dynamic"
  }

  tags = local.mandatory_tags
}

# ─── Outbound Endpoint (optional) ────────────────────────────────────────────
# Created only when outbound_subnet_id is provided (non-empty string).
# Required for DNS forwarding to on-premises or external DNS servers.

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  count = var.outbound_subnet_id != "" ? 1 : 0

  name                    = "${var.name_prefix}-${var.environment}-dnsresolver-outbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location
  subnet_id               = var.outbound_subnet_id

  tags = local.mandatory_tags
}

# ─── DNS Forwarding Rulesets (optional, for_each) ────────────────────────────
# Created only when dns_forwarding_rulesets map is non-empty.
# Requires an outbound endpoint — outbound_subnet_id must be set when using rulesets.

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "this" {
  for_each = var.dns_forwarding_rulesets

  name                                       = each.key
  resource_group_name                        = var.resource_group_name
  location                                   = var.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.this[0].id]

  tags = local.mandatory_tags
}
