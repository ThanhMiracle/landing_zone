# =============================================================================
# infra/environments/uat/terragrunt.hcl
#
# Root config cho environment uat.
# Chạy: cd infra/environments/uat && terragrunt run-all apply
#
# File này là root config — cung cấp remote_state và generate cho tất cả stacks.
# Không có `include "root"` để tránh circular include.
# Requirements: R11.1, R11.2, R11.6, R4.1-R4.8
# =============================================================================

locals {
  use_local_backend = tobool(get_env("TERRAGRUNT_USE_LOCAL_BACKEND", "false"))
}

remote_state {
  backend = local.use_local_backend ? "local" : "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = local.use_local_backend ? {
    path = "${get_original_terragrunt_dir()}/terraform.tfstate"
  } : {
    resource_group_name  = "rg-tfstate"
    storage_account_name = get_env("TF_VAR_tfstate_storage_account", "tfstatemyproject")
    container_name       = "tfstate"
    key                  = "uat/${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "azurerm_provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
EOF
}
