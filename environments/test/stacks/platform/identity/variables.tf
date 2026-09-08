# infra/stacks/platform/identity/variables.tf

variable "subscription_id" {
  description = "Azure Subscription ID cho identity platform subscription."
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

# ---------------------------------------------------------------------------
# R10.6, R15.7: Azure AD Domain Services (AD DS) variables
# Chỉ có hiệu lực khi deploy_identity_ds = true
# ---------------------------------------------------------------------------

variable "deploy_identity_ds" {
  description = "Bật để deploy azurerm_active_directory_domain_service. Yêu cầu Azure AD Premium P1/P2."
  type        = bool
  default     = false
}

variable "adds_domain_name" {
  description = "FQDN của Azure AD DS domain."
  type        = string
  default     = ""
}

variable "adds_sku" {
  description = "SKU của Azure AD DS. Allowed: Standard, Enterprise, Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Enterprise", "Premium"], var.adds_sku)
    error_message = "adds_sku must be one of: Standard, Enterprise, Premium."
  }
}

variable "adds_subnet_id" {
  description = "Resource ID của subnet dành riêng cho AD DS domain controllers."
  type        = string
  default     = ""
}
