# =============================================================================
# environments/thanh/root.hcl
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
    resource_group_name = "rg-tfstate"
    storage_account_name = get_env(
      "TF_VAR_tfstate_storage_account",
      "thanhdepzaivl2001"
    )
    container_name = "tfstate"
    key            = "thanh/${path_relative_to_include()}/terraform.tfstate"

    # Quan trọng
    use_azuread_auth = true
    use_cli          = true
  }
}

generate "azurerm_provider" {
  path      = "required_providers_generated.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.81.0"
    }
  }
}
EOF
}