# infra/stacks/platform/connectivity/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Download the repository root so Terraform's local ../../.. module paths stay valid in Terragrunt's cache.
terraform {
  source = "${dirname(dirname(get_parent_terragrunt_dir()))}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

exclude {
  if      = !local.env_vars.locals.deploy_connectivity
  actions = ["all"]
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = "${local.env_vars.locals.connectivity_subscription_id}"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
EOF
}

inputs = {
  subscription_id             = local.env_vars.locals.connectivity_subscription_id
  name_prefix                 = local.env_vars.locals.name_prefix
  environment                 = "connectivity"
  location                    = local.env_vars.locals.location
  hub_address_space           = local.env_vars.locals.hub_address_space
  hub_subnets                 = local.env_vars.locals.hub_subnets
  aks_subnet_address_prefixes = local.env_vars.locals.app_subnets.aks.address_prefixes
  aks_additional_fqdns = [
    "*.vault.azure.net",
    "*.ods.opinsights.azure.com",
    "*.oms.opinsights.azure.com",
    "${local.env_vars.locals.name_prefix}${local.env_vars.locals.environment}acr.azurecr.io",
    "${local.env_vars.locals.name_prefix}${local.env_vars.locals.environment}st.blob.core.windows.net",
    # Standard ACR redirects image-layer downloads to Azure-managed Blob storage.
    # ACR's managed storage hostname is not stable, so the documented endpoint
    # pattern is required while dedicated ACR data endpoints are unavailable.
    "*.blob.core.windows.net",
    # Docker Hub image pulls: registry, bearer-token service, and image-layer CDN.
    "registry-1.docker.io",
    "auth.docker.io",
    "production.cloudfront.docker.com",
  ]
  deploy_firewall     = local.env_vars.locals.deploy_firewall
  deploy_vpn_gateway  = local.env_vars.locals.deploy_vpn_gateway
  deploy_dns_resolver = local.env_vars.locals.deploy_dns_resolver
  tags                = merge(local.env_vars.locals.common_tags, { Layer = "connectivity" })
}
