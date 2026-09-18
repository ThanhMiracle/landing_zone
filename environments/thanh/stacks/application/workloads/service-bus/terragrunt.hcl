# infra/stacks/application/workloads/service-bus/terragrunt.hcl
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

# R2: Dùng deploy_service_bus thay cho deploy_apim — deploy_apim là tên cũ không còn dùng cho stack này
exclude {
  if      = !local.env_vars.locals.deploy_service_bus
  actions = ["all"]
}

dependency "baseline" {
  config_path = "../../../application/baseline"
  mock_outputs = {
    spoke_vnet_id             = "mock-spoke-vnet-id"
    key_vault_id              = "mock-kv-id"
    managed_identity_id       = "mock-mi-id"
    spoke_resource_group_name = "mock-spoke-rg"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "management" {
  config_path = "../../../platform/management"
  mock_outputs = {
    log_analytics_workspace_id = "mock-workspace-id"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
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
EOF
}

inputs = {
  subscription_id            = local.env_vars.locals.app_subscription_id
  name_prefix                = local.env_vars.locals.name_prefix
  environment                = local.env_vars.locals.environment
  location                   = local.env_vars.locals.location
  spoke_vnet_id              = dependency.baseline.outputs.spoke_vnet_id
  key_vault_id               = dependency.baseline.outputs.key_vault_id
  managed_identity_id        = dependency.baseline.outputs.managed_identity_id
  log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id
  tags                       = local.env_vars.locals.common_tags
}
