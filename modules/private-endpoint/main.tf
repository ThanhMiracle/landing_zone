terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = "${var.name_prefix}-${var.environment}-pep"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-${var.environment}-psc"
    private_connection_resource_id = var.resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Optional: create a private DNS zone when create_dns_zone = true
resource "azurerm_private_dns_zone" "this" {
  count               = var.create_dns_zone ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Optional: link the DNS zone to the VNet when create_dns_zone = true
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count                 = var.create_dns_zone ? 1 : 0
  name                  = "${var.name_prefix}-${var.environment}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
