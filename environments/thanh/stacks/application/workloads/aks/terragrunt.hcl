include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_path_to_repo_root()}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  app_subscription_id        = local.env_vars.locals.app_subscription_id
  management_subscription_id = local.env_vars.locals.management_subscription_id

  mock_spoke_rg = "mock-spoke-rg"
}

exclude {
  if      = !local.env_vars.locals.deploy_aks
  actions = ["all"]
}

dependency "baseline" {
  config_path = "../../baseline"

  mock_outputs = {
    spoke_vnet_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet"

    key_vault_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.KeyVault/vaults/mock-kv"

    managed_identity_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock-mi"

    spoke_resource_group_name = local.mock_spoke_rg

    aks_subnet_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/aks"

    container_registry_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.ContainerRegistry/registries/mockacr"
  }

  mock_outputs_allowed_terraform_commands = [
    "validate",
    "plan"
  ]
}

dependency "management" {
  config_path = "../../../platform/management"

  mock_outputs = {
    log_analytics_workspace_id = "/subscriptions/${local.management_subscription_id}/resourceGroups/mock-management-rg/providers/Microsoft.OperationalInsights/workspaces/mock-law"
  }

  mock_outputs_allowed_terraform_commands = [
    "validate",
    "plan"
  ]
}

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

inputs = {
  subscription_id = local.app_subscription_id
  name_prefix     = local.env_vars.locals.name_prefix
  environment     = local.env_vars.locals.environment
  location        = local.env_vars.locals.location

  spoke_vnet_id         = dependency.baseline.outputs.spoke_vnet_id
  key_vault_id          = dependency.baseline.outputs.key_vault_id
  managed_identity_id   = dependency.baseline.outputs.managed_identity_id
  resource_group_name   = dependency.baseline.outputs.spoke_resource_group_name
  aks_subnet_id         = dependency.baseline.outputs.aks_subnet_id
  container_registry_id = dependency.baseline.outputs.container_registry_id

  log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id

  tags = local.env_vars.locals.common_tags
}