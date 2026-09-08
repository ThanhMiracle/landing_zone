terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  common_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Public IP — only created for public load balancer
resource "azurerm_public_ip" "this" {
  count = var.lb_type == "public" ? 1 : 0

  name                = "${var.name_prefix}-${var.environment}-lb-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_lb" "this" {
  name                = "${var.name_prefix}-${var.environment}-lb"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name = "frontend"

    # Public LB
    public_ip_address_id = var.lb_type == "public" ? azurerm_public_ip.this[0].id : null

    # Internal LB
    subnet_id                     = var.lb_type == "internal" ? var.subnet_id : null
    private_ip_address_allocation = var.lb_type == "internal" ? "Dynamic" : null
  }

  tags = local.common_tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = "${var.name_prefix}-${var.environment}-lb-pool"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "this" {
  name            = "${var.name_prefix}-${var.environment}-lb-probe"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = var.probe_protocol
  port            = var.probe_port
  request_path    = var.probe_protocol == "Http" || var.probe_protocol == "Https" ? var.probe_request_path : null
}

resource "azurerm_lb_rule" "this" {
  for_each = var.lb_rules

  name                           = each.key
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
}
