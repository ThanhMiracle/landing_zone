include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${dirname(dirname(get_parent_terragrunt_dir()))}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  app_subscription_id        = local.env_vars.locals.app_subscription_id
  management_subscription_id = local.env_vars.locals.management_subscription_id
  mock_spoke_rg              = "mock-spoke-rg"
}

exclude {
  if      = !local.env_vars.locals.deploy_blob_storage
  actions = ["all"]
}

dependency "baseline" {
  config_path = "../../baseline"

  mock_outputs = {
    spoke_resource_group_name = local.mock_spoke_rg
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "aks" {
  config_path = "../aks"

  mock_outputs = {
    aks_kubelet_identity_object_id = "00000000-0000-0000-0000-000000000000"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "management" {
  config_path = "../../../platform/management"

  mock_outputs = {
    log_analytics_workspace_id = "/subscriptions/${local.management_subscription_id}/resourceGroups/mock-management-rg/providers/Microsoft.OperationalInsights/workspaces/mock-law"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
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

  resource_group_name            = dependency.baseline.outputs.spoke_resource_group_name
  aks_kubelet_identity_object_id = dependency.aks.outputs.aks_kubelet_identity_object_id
  log_analytics_workspace_id     = dependency.management.outputs.log_analytics_workspace_id

  tags = local.env_vars.locals.common_tags
}
