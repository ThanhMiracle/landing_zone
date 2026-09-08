terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Enable Microsoft Defender for Cloud (Standard tier) for each resource type.
# Uses for_each over var.resource_types so plans can be added/removed
# without destroying the entire set.
# ---------------------------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = var.resource_types
  resource_type = each.value
  tier          = "Standard"
}
