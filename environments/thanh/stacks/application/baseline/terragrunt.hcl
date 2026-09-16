# infra/stacks/application/baseline/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

# Download the repository root so Terraform's local ../../.. module paths
# stay valid in Terragrunt's cache.
terraform {
  source = "${get_path_to_repo_root()}//${path_relative_to_include()}"
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
    hub_resource_group_name = local.mock_hub_resource_group_name
    dns_server_ip           = null
  }

  mock_outputs_allowed_terraform_commands = [
    "validate",
    "plan"
  ]
}

# ---------------------------------------------------------------------------
# Platform Management dependency
# ---------------------------------------------------------------------------

dependency "management" {
  config_path = "../../platform/management"

  mock_outputs = {
    log_analytics_workspace_id = local.mock_log_analytics_workspace_id

    # Mock only. Real value comes from platform/management state during apply.
    log_analytics_workspace_key = "mock-workspace-key"
  }

  mock_outputs_allowed_terraform_commands = [
    "validate",
    "plan"
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

  features {}
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
  app_vnet_address_space = local.env_vars.locals.app_vnet_address_space
  app_subnets            = local.env_vars.locals.app_subnets

  # Connectivity
  hub_vnet_id             = dependency.connectivity.outputs.hub_vnet_id
  firewall_private_ip     = dependency.connectivity.outputs.firewall_private_ip
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

  log_analytics_workspace_key = (
    dependency.management.outputs.log_analytics_workspace_key
  )

  tags = local.env_vars.locals.common_tags
}