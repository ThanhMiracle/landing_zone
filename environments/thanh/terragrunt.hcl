# =============================================================================
# infra/environments/dev/terragrunt.hcl
#
# Root config cho environment dev.
# Chạy toàn bộ landing zone bằng một lệnh:
#   cd infra/environments/dev
#   terragrunt run-all apply
#
# Cơ chế discovery:
#   Thư mục `stacks/` trong cùng directory này là một junction point trỏ tới
#   `infra/stacks/`. Khi `run-all` quét đệ quy (hoặc chạy từng stack riêng),
#   file này được pick up qua `find_in_parent_folders()` từ các stack bên trong.
#
#   Mỗi stack gọi `find_in_parent_folders("env.hcl")` — Terragrunt traverse
#   ngược từ `environments/dev/stacks/<stack-path>/` lên và tìm `env.hcl`
#   tại `environments/dev/env.hcl`. Đây là nguồn sự thật duy nhất cho env.
#
#   QUAN TRỌNG: File này là root config — cung cấp remote_state và generate
#   cho tất cả stacks trong environment này. Không có `include "root"` ở đây
#   để tránh circular include.
#
# Requirements: R11.1, R11.2, R11.6, R4.1-R4.8
# =============================================================================

locals {
  # Set TERRAGRUNT_USE_LOCAL_BACKEND=true to use local backend for validate/plan without Azure credentials
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
    storage_account_name = get_env("TF_VAR_tfstate_storage_account", "thanhdepzaivl2001")
    container_name       = "tfstate"
    key                  = "thanh/${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "azurerm_provider" {
  path      = "required_providers_generated.tf"
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
