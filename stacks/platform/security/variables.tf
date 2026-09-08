# infra/stacks/platform/security/variables.tf

variable "subscription_id" {
  description = "Azure Subscription ID cho security platform subscription."
  type        = string
}

variable "name_prefix" {
  description = "Tiền tố dự án dùng trong naming convention. Tối đa 10 ký tự lowercase."
  type        = string
}

variable "environment" {
  description = "Tên environment (dev, staging, prod)."
  type        = string
}

variable "location" {
  description = "Azure region để deploy resources (ví dụ: southeastasia)."
  type        = string
}

variable "tags" {
  description = "Tags áp dụng lên tất cả resources trong stack này."
  type        = map(string)
  default     = {}
}

# R11.6, R19.6: Sentinel onboarding flag
variable "deploy_sentinel" {
  description = "Bật để onboard Microsoft Sentinel lên Log Analytics workspace của Management stack."
  type        = bool
  default     = false
}

# R11.6, R19.6: Defender for Cloud flag
variable "deploy_defender_plans" {
  description = "Bật để enable Defender for Cloud pricing plans."
  type        = bool
  default     = false
}

# R15.7: Log Analytics workspace ID từ Management stack
variable "log_analytics_workspace_id" {
  description = "Resource ID của Log Analytics workspace từ Management stack. Cần thiết khi deploy_sentinel = true."
  type        = string
  default     = null
}
