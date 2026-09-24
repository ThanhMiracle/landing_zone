# infra/stacks/application/baseline/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Download the repository root so Terraform's local ../../.. module paths
# stay valid in Terragrunt's cache.
terraform {
  source = "${dirname(dirname(get_parent_terragrunt_dir()))}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )

  # Shortcuts
  app_subscription_id          = local.env_vars.locals.app_subscription_id
  connectivity_subscription_id = local.env_vars.locals.connectivity_subscription_id
  management_subscription_id   = local.env_vars.locals.management_subscription_id
  name_prefix                  = local.env_vars.locals.name_prefix
  environment                  = local.env_vars.locals.environment

  # -------------------------------------------------------------------------
  # Valid-format mock Azure Resource IDs
  #
  # These resources do NOT need to actually exist for validate/plan.
  # They only need to follow the Azure Resource ID format expected by
  # the AzureRM provider.
  # -------------------------------------------------------------------------

  mock_hub_resource_group_name = "${local.name_prefix}-${local.environment}-connectivity-rg"

  mock_hub_vnet_id = "/subscriptions/${local.connectivity_subscription_id}/resourceGroups/${local.mock_hub_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.name_prefix}-${local.environment}-hub-vnet"

  mock_log_analytics_workspace_id = "/subscriptions/${local.management_subscription_id}/resourceGroups/${local.name_prefix}-${local.environment}-management-rg/providers/Microsoft.OperationalInsights/workspaces/${local.name_prefix}-${local.environment}-law"
}

# ---------------------------------------------------------------------------
# Platform Connectivity dependency
# ---------------------------------------------------------------------------

dependency "connectivity" {
  config_path = "../../platform/connectivity"

  mock_outputs = {
    hub_vnet_id             = local.mock_hub_vnet_id
    firewall_private_ip     = "10.0.0.4"
    firewall_public_ip      = "203.0.113.10"
    hub_resource_group_name = local.mock_hub_resource_group_name
    dns_server_ip           = null
  }

  mock_outputs_allowed_terraform_commands = [
    "init",
    "validate",
    "plan",
    "destroy"
  ]
}

# ---------------------------------------------------------------------------
# Platform Management dependency
# ---------------------------------------------------------------------------

dependency "management" {
  config_path = "../../platform/management"

  mock_outputs = {
    log_analytics_workspace_id = local.mock_log_analytics_workspace_id
  }

  mock_outputs_allowed_terraform_commands = [
    "init",
    "validate",
    "plan",
    "destroy"
  ]
}

# ---------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "azurerm" {
  alias           = "workload"
  subscription_id = "${local.app_subscription_id}"

  features {
    resource_group {
      # Application Insights creates a smart-detection action group outside
      # Terraform state. This RG is dedicated to the Thanh environment.
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = "${local.connectivity_subscription_id}"

  features {}
}
EOF
}

# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------

inputs = {
  subscription_id        = local.app_subscription_id
  name_prefix            = local.name_prefix
  environment            = local.environment
  location               = local.env_vars.locals.location
  github_repository      = local.env_vars.locals.github_repository
  github_oidc_subject    = local.env_vars.locals.github_oidc_subject
  app_vnet_address_space = local.env_vars.locals.app_vnet_address_space
  app_subnets            = local.env_vars.locals.app_subnets

  # Connectivity
  hub_vnet_id             = dependency.connectivity.outputs.hub_vnet_id
  firewall_private_ip     = dependency.connectivity.outputs.firewall_private_ip
  firewall_public_ip      = dependency.connectivity.outputs.firewall_public_ip
  hub_resource_group_name = dependency.connectivity.outputs.hub_resource_group_name

  # DNS Resolver is optional.
  # Terraform may omit null outputs from state, so use null as fallback.
  dns_server_ip = try(
    dependency.connectivity.outputs.dns_server_ip,
    null
  )

  # Management / Observability
  log_analytics_workspace_id = (
    dependency.management.outputs.log_analytics_workspace_id
  )

  tags = local.env_vars.locals.common_tags
}
