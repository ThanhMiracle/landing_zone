# infra/stacks/platform/security/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

# Download the repository root so Terraform's local ../../.. module paths stay valid in Terragrunt's cache.
terraform {
  source = "${dirname(dirname(get_parent_terragrunt_dir()))}//${path_relative_to_include()}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# deploy_security defaults to false — scaffold only (R7, R10.10)
exclude {
  if      = !local.env_vars.locals.deploy_security
  actions = ["all"]
}

# R11.5, R11.8, R19.1, R19.4: Dependency on management stack for Log Analytics workspace ID
# Required by Sentinel onboarding — mock_outputs allow validate/plan without real state
dependency "management" {
  config_path = "../../platform/management"
  mock_outputs = {
    log_analytics_workspace_id = "mock-workspace-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  alias           = "security"
  subscription_id = "${local.env_vars.locals.security_subscription_id}"
  features {}
}
EOF
}

inputs = {
  subscription_id = local.env_vars.locals.security_subscription_id
  name_prefix     = local.env_vars.locals.name_prefix
  environment     = local.env_vars.locals.environment
  location        = local.env_vars.locals.location
  tags            = local.env_vars.locals.common_tags

  # R11.5, R19.1: Sprint 3 Security flags — control Sentinel and Defender deployments
  deploy_sentinel            = local.env_vars.locals.deploy_sentinel
  deploy_defender_plans      = local.env_vars.locals.deploy_defender_plans
  log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id
}
