# infra/modules/management-group/outputs.tf

output "management_group_id" {
  value       = azurerm_management_group.this.id
  description = "Resource ID đầy đủ của Management Group. Ví dụ: '/providers/Microsoft.Management/managementGroups/myproject-platform'. Dùng làm parent_management_group_id cho child management groups."
}

output "management_group_name" {
  value       = azurerm_management_group.this.name
  description = "Tên kỹ thuật (slug) của Management Group như đã được tạo trong Azure. Kết hợp từ name_prefix và name đầu vào."
}
