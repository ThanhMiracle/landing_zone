# =============================================================================
# infra/stacks/platform/connectivity/firewall.tf
# Azure Firewall — conditional hub component.
# Deployed only when var.deploy_firewall = true (count = 1).
# When deploy_firewall = false, no azurerm_firewall resource is created (count = 0).
# =============================================================================

module "firewall" {
  source = "../../../modules/firewall"
  count  = var.deploy_firewall ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.hub_vnet.subnet_ids["AzureFirewallSubnet"]
  network_rule_collections = length(var.aks_subnet_address_prefixes) > 0 ? {
    aks_azure_services = {
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "aks-monitoring-and-registry"
          protocols             = ["TCP"]
          source_addresses      = var.aks_subnet_address_prefixes
          destination_addresses = ["AzureMonitor", "AzureContainerRegistry"]
          destination_ports     = ["443"]
        },
      ]
    }
  } : {}
  application_rule_collections = length(var.aks_subnet_address_prefixes) > 0 ? {
    aks_platform = {
      priority = 200
      action   = "Allow"
      rules = [
        {
          name                  = "aks-required-platform-fqdns"
          source_addresses      = var.aks_subnet_address_prefixes
          destination_fqdn_tags = ["AzureKubernetesService"]
          protocols = [
            { type = "Https", port = 443 },
            { type = "Http", port = 80 },
          ]
        },
        {
          name              = "aks-enabled-services"
          source_addresses  = var.aks_subnet_address_prefixes
          destination_fqdns = var.aks_additional_fqdns
          protocols = [
            { type = "Https", port = 443 },
          ]
        },
      ]
    }
  } : {}
  # With the AKS subnet forced through this firewall by UDR, public ingress
  # must enter through the firewall too. Otherwise its return traffic is
  # asymmetric and Azure Firewall drops it.
  dnat_rule_collections = var.aks_ingress_load_balancer_ip != null ? {
    aks_public_http = {
      priority = 300
      action   = "Dnat"
      rules = [
        {
          name                = "http-to-aks-nginx-load-balancer"
          protocols           = ["TCP"]
          source_addresses    = ["*"]
          destination_address = null
          destination_ports   = ["80"]
          translated_address  = var.aks_ingress_load_balancer_ip
          translated_port     = "80"
        },
      ]
    }
  } : {}
  tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
