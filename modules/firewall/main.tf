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

# ─── Public IP for Azure Firewall frontend ────────────────────────────────────

resource "azurerm_public_ip" "firewall" {
  name                = "${var.name_prefix}-${var.environment}-fw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.mandatory_tags
}

# ─── Firewall Policy ──────────────────────────────────────────────────────────

resource "azurerm_firewall_policy" "this" {
  name                = "${var.name_prefix}-${var.environment}-fw-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.firewall_sku_tier

  tags = local.mandatory_tags
}

# ─── Rule Collection Group (always created; collections are optional) ─────────

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = "${var.name_prefix}-${var.environment}-fw-rcg"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = var.rule_collection_group_priority

  # ── Network rule collections (for_each; empty map → no blocks) ──────────────
  dynamic "network_rule_collection" {
    for_each = var.network_rule_collections
    content {
      name     = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  # ── Application rule collections (for_each; empty map → no blocks) ──────────
  dynamic "application_rule_collection" {
    for_each = var.application_rule_collections
    content {
      name     = application_rule_collection.key
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.value.name
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  # ── DNAT rule collections (for_each; empty map → no blocks) ─────────────────
  dynamic "nat_rule_collection" {
    for_each = var.dnat_rule_collections
    content {
      name     = nat_rule_collection.key
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.value.name
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

# ─── Azure Firewall ───────────────────────────────────────────────────────────

resource "azurerm_firewall" "this" {
  name                = "${var.name_prefix}-${var.environment}-fw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.mandatory_tags
}
