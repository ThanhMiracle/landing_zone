# infra/stacks/application/workloads/postgresql/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(dirname(get_parent_terragrunt_dir()))}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )

  app_subscription_id        = local.env_vars.locals.app_subscription_id
  management_subscription_id = local.env_vars.locals.management_subscription_id

  mock_spoke_rg = "mock-spoke-rg"
}

exclude {
  if      = !local.env_vars.locals.deploy_postgresql
  actions = ["all"]
}

# ---------------------------------------------------------------------------
# Application baseline
# ---------------------------------------------------------------------------

dependency "baseline" {
  config_path = "../../baseline"

  mock_outputs = {
    spoke_vnet_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet"

    data_subnet_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/data"

    key_vault_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.KeyVault/vaults/mock-kv"

    managed_identity_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock-mi"

    spoke_resource_group_name = local.mock_spoke_rg
  }

  mock_outputs_allowed_terraform_commands = [
    "init",
    "validate",
    "plan",
    "destroy"
  ]
}

# ---------------------------------------------------------------------------
# Platform management
# ---------------------------------------------------------------------------

dependency "management" {
  config_path = "../../../platform/management"

  mock_outputs = {
    log_analytics_workspace_id = "/subscriptions/${local.management_subscription_id}/resourceGroups/mock-management-rg/providers/Microsoft.OperationalInsights/workspaces/mock-law"
  }

  mock_outputs_allowed_terraform_commands = [
    "init",
    "validate",
    "plan",
    "destroy"
  ]
}

# ---------------------------------------------------------------------------
# Provider
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
EOF
}

# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------

inputs = {
  subscription_id = local.app_subscription_id
  name_prefix     = local.env_vars.locals.name_prefix
  environment     = local.env_vars.locals.environment
  location        = local.env_vars.locals.location

  spoke_vnet_id = dependency.baseline.outputs.spoke_vnet_id
  # PostgreSQL receives the delegated subnet directly from baseline.
  data_subnet_id = dependency.baseline.outputs.data_subnet_id

  key_vault_id = dependency.baseline.outputs.key_vault_id

  managed_identity_id = dependency.baseline.outputs.managed_identity_id

  resource_group_name = dependency.baseline.outputs.spoke_resource_group_name

  log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id

  tags = local.env_vars.locals.common_tags
}
