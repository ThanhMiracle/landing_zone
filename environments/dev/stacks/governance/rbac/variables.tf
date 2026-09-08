# infra/stacks/governance/rbac/variables.tf
# R9.3, R9.7, R9.9, R15.7

variable "name_prefix" {
  description = "Tiền tố dự án dùng trong naming convention."
  type        = string
}

variable "environment" {
  description = "Tên environment (dev, staging, prod)."
  type        = string
}

variable "rbac_assignments" {
  description = "Map các RBAC role assignments cần tạo. Key là tên định danh, value chứa principal_id, role_definition_name, scope. Khi map rỗng, không có assignment nào được tạo."
  type = map(object({
    principal_id         = string
    role_definition_name = string
    scope                = string
  }))
  default = {}
}
