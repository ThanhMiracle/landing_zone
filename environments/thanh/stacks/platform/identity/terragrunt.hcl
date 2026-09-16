# infra/stacks/platform/identity/terragrunt.hcl
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

# deploy_identity defaults to false — scaffold only (R6, R10.10)
exclude {
  if      = !local.env_vars.locals.deploy_identity
  actions = ["all"]
}

# TODO: Future resources — Entra ID, Azure AD Domain Services, Conditional Access

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  alias           = "identity"
  subscription_id = "${local.env_vars.locals.identity_subscription_id}"
  features {}
}
EOF
}

inputs = {
  subscription_id    = local.env_vars.locals.identity_subscription_id
  name_prefix        = local.env_vars.locals.name_prefix
  environment        = local.env_vars.locals.environment
  location           = local.env_vars.locals.location
  tags               = local.env_vars.locals.common_tags
  deploy_identity_ds = local.env_vars.locals.deploy_identity_ds
}
