# infra/stacks/management-groups/variables.tf

variable "name_prefix" {
  description = "Tiền tố dự án dùng trong naming convention. Tối đa 10 ký tự lowercase."
  type        = string
}

variable "environment" {
  description = "Tên environment (dev, staging, prod)."
  type        = string
}

variable "location" {
  description = "Azure region (không dùng trực tiếp cho management groups, nhưng cần cho consistency)."
  type        = string
  default     = ""
}

variable "connectivity_subscription_id" {
  description = "Azure Subscription ID cho connectivity platform subscription."
  type        = string
  default     = ""
}

variable "management_subscription_id" {
  description = "Azure Subscription ID cho management platform subscription."
  type        = string
  default     = ""
}

variable "identity_subscription_id" {
  description = "Azure Subscription ID cho identity platform subscription."
  type        = string
  default     = ""
}

variable "security_subscription_id" {
  description = "Azure Subscription ID cho security platform subscription."
  type        = string
  default     = ""
}

variable "app_subscription_id" {
  description = "Azure Subscription ID cho application workloads subscription."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags áp dụng lên Management Groups."
  type        = map(string)
  default     = {}
}
