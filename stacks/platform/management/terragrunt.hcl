# infra/stacks/platform/management/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

skip = !local.env_vars.locals.deploy_management

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
