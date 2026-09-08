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

# ─── Public IP for VPN Gateway frontend ──────────────────────────────────────

resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${var.name_prefix}-${var.environment}-vpngw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.mandatory_tags
}

# ─── VPN Gateway ─────────────────────────────────────────────────────────────

resource "azurerm_virtual_network_gateway" "this" {
  name                = "${var.name_prefix}-${var.environment}-vpngw"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.sku

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.gateway_subnet_id
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.mandatory_tags
}

# ─── Local Network Gateways (one per VPN connection) ─────────────────────────
# Only created when vpn_connections is non-empty

resource "azurerm_local_network_gateway" "this" {
  for_each = var.vpn_connections

  name                = "${var.name_prefix}-${var.environment}-lng-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = each.value.local_gateway_address
  address_space       = each.value.address_spaces

  tags = local.mandatory_tags
}

# ─── VPN Gateway Connections (one per VPN connection) ────────────────────────
# Only created when vpn_connections is non-empty

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = var.vpn_connections

  name                       = "${var.name_prefix}-${var.environment}-conn-${each.key}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this[each.key].id
  shared_key                 = sensitive(each.value.shared_key)

  tags = local.mandatory_tags
}
