# infra/stacks/platform/management/terragrunt.hcl
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

exclude {
  if      = !local.env_vars.locals.deploy_management
  actions = ["all"]
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  alias           = "management"
  subscription_id = "${local.env_vars.locals.management_subscription_id}"
  features {}
}
EOF
}

inputs = {
  subscription_id = local.env_vars.locals.management_subscription_id
  name_prefix     = local.env_vars.locals.name_prefix
  environment     = local.env_vars.locals.environment
  location        = local.env_vars.locals.location
  tags            = local.env_vars.locals.common_tags
}
