include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(dirname(get_parent_terragrunt_dir()))}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  app_subscription_id        = local.env_vars.locals.app_subscription_id
  management_subscription_id = local.env_vars.locals.management_subscription_id
  aks_outbound_type          = local.env_vars.locals.deploy_firewall ? "userDefinedRouting" : "loadBalancer"

  mock_spoke_rg = "mock-spoke-rg"
}

exclude {
  if      = !local.env_vars.locals.deploy_aks
  actions = ["all"]
}

dependency "baseline" {
  config_path = "../../baseline"

  mock_outputs = {
    key_vault_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.KeyVault/vaults/mock-kv"

    managed_identity_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock-mi"

    managed_identity_principal_id = "00000000-0000-0000-0000-000000000001"

    spoke_resource_group_name = local.mock_spoke_rg

    aks_subnet_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/aks"

    aks_route_table_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.Network/routeTables/mock-aks-rt"

    container_registry_id = "/subscriptions/${local.app_subscription_id}/resourceGroups/${local.mock_spoke_rg}/providers/Microsoft.ContainerRegistry/registries/mockacr"
  }

  mock_outputs_allowed_terraform_commands = [
    "init",
    "validate",
    "plan",
    "destroy"
  ]
}

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

  key_vault_id                  = dependency.baseline.outputs.key_vault_id
  managed_identity_id           = dependency.baseline.outputs.managed_identity_id
  managed_identity_principal_id = dependency.baseline.outputs.managed_identity_principal_id
  resource_group_name           = dependency.baseline.outputs.spoke_resource_group_name
  aks_subnet_id                 = dependency.baseline.outputs.aks_subnet_id
  aks_route_table_id            = dependency.baseline.outputs.aks_route_table_id
  container_registry_id         = dependency.baseline.outputs.container_registry_id
  github_deploy_oidc_subject    = local.env_vars.locals.github_deploy_oidc_subject
  outbound_type                 = local.aks_outbound_type
  service_cidr                  = local.env_vars.locals.aks_service_cidr
  dns_service_ip                = local.env_vars.locals.aks_dns_service_ip

  log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id
  # Temporary state recovery for the setting that already exists in Azure.
  adopt_existing_diagnostic_setting = true

  tags = local.env_vars.locals.common_tags
}
