# infra/stacks/governance/rbac/terragrunt.hcl
# R9: RBAC cross-subscription stack
# Gán roles chuẩn cho các teams theo nguyên tắc least privilege.
# Kiểm soát bởi deploy_rbac flag và rbac_assignments map trong env.hcl.

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

# Mặc định skip = true — không gán RBAC nếu chưa cấu hình
exclude {
  if      = !local.env_vars.locals.deploy_rbac
  actions = ["all"]
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# RBAC stack dùng default provider (không cần subscription-specific alias)
# vì azurerm_role_assignment scope tự chỉ định subscription qua `scope` field
provider "azurerm" {
  subscription_id = "${local.env_vars.locals.app_subscription_id}"
  features {}
}
EOF
}

inputs = {
  name_prefix      = local.env_vars.locals.name_prefix
  environment      = local.env_vars.locals.environment
  rbac_assignments = local.env_vars.locals.rbac_assignments
}
