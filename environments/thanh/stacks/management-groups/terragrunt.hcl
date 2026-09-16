# infra/stacks/management-groups/terragrunt.hcl
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
  if      = !local.env_vars.locals.deploy_management_groups
  actions = ["all"]
}

# Không có dependency blocks — runs first (Tier 0)

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  subscription_id = "${local.env_vars.locals.management_subscription_id}"
  features {}
}
EOF
}

inputs = {
  name_prefix                  = local.env_vars.locals.name_prefix
  environment                  = local.env_vars.locals.environment
  tags                         = local.env_vars.locals.common_tags
  connectivity_subscription_id = local.env_vars.locals.connectivity_subscription_id
  management_subscription_id   = local.env_vars.locals.management_subscription_id
  identity_subscription_id     = local.env_vars.locals.identity_subscription_id
  security_subscription_id     = local.env_vars.locals.security_subscription_id
  app_subscription_id          = local.env_vars.locals.app_subscription_id
}
