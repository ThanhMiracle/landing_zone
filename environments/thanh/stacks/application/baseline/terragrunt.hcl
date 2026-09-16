# infra/stacks/application/baseline/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

# Download the repository root so Terraform's local ../../.. module paths stay valid in Terragrunt's cache.
terraform {
  source = "${get_path_to_repo_root()}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# No skip condition — always deploy if app_subscription_id is set

dependency "connectivity" {
  config_path = "../../platform/connectivity"
  mock_outputs = {
    hub_vnet_id             = "mock-hub-vnet-id"
    firewall_private_ip     = "10.0.0.4"
    hub_resource_group_name = "mock-connectivity-rg"
    dns_server_ip           = null
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "management" {
  config_path = "../../platform/management"
  mock_outputs = {
    log_analytics_workspace_id  = "mock-workspace-id"
    log_analytics_workspace_key = "mock-workspace-key"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  alias           = "workload"
  subscription_id = "${local.env_vars.locals.app_subscription_id}"
  features {}
}
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = "${local.env_vars.locals.connectivity_subscription_id}"
  features {}
}
EOF
}

inputs = {
  subscription_id             = local.env_vars.locals.app_subscription_id
  name_prefix                 = local.env_vars.locals.name_prefix
  environment                 = local.env_vars.locals.environment
  location                    = local.env_vars.locals.location
  app_vnet_address_space      = local.env_vars.locals.app_vnet_address_space
  app_subnets                 = local.env_vars.locals.app_subnets
  hub_vnet_id                 = dependency.connectivity.outputs.hub_vnet_id
  firewall_private_ip         = dependency.connectivity.outputs.firewall_private_ip
  hub_resource_group_name     = dependency.connectivity.outputs.hub_resource_group_name
  # The DNS Resolver is optional. Terraform omits null outputs from state, so
  # fall back to null when deploy_dns_resolver is false.
  dns_server_ip               = try(dependency.connectivity.outputs.dns_server_ip, null)
  log_analytics_workspace_id  = dependency.management.outputs.log_analytics_workspace_id
  log_analytics_workspace_key = dependency.management.outputs.log_analytics_workspace_key
  tags                        = local.env_vars.locals.common_tags
}
