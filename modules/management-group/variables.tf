# infra/modules/management-group/variables.tf

variable "name" {
  description = "Tên kỹ thuật (slug) của Management Group, dùng làm ID. Ví dụ: 'platform', 'application'. Phải unique trong tenant."
  type        = string
}

variable "display_name" {
  description = "Tên hiển thị của Management Group trong Azure Portal. Ví dụ: 'Platform', 'Application Landing Zones'."
  type        = string
}

variable "name_prefix" {
  description = "Tiền tố dự án, kết hợp với name để tạo management group ID. Ví dụ: 'myproject'. Tối đa 10 ký tự lowercase."
  type        = string
}

variable "parent_management_group_id" {
  description = "Resource ID của Management Group cha. Để null để sử dụng Tenant Root Group mặc định. Ví dụ: '/providers/Microsoft.Management/managementGroups/tenant-root-mg'."
  type        = string
  default     = null
  nullable    = true
}

variable "subscriptions" {
  description = "Danh sách Azure Subscription IDs cần gắn vào Management Group này. Để rỗng nếu không có subscription nào cần gắn. Ví dụ: ['00000000-0000-0000-0000-000000000001']."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags bổ sung để áp dụng lên Management Group. Merge với mandatory tags từ calling stack."
  type        = map(string)
  default     = {}
}
