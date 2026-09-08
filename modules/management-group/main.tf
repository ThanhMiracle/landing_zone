# infra/modules/management-group/main.tf

resource "azurerm_management_group" "this" {
  # ID tổng hợp: {name_prefix}-{name} — unique trong tenant
  # Ví dụ: "myproject-platform", "myproject-application"
  name         = "${var.name_prefix}-${var.name}"
  display_name = var.display_name

  # Null = gắn vào Tenant Root Group
  parent_management_group_id = var.parent_management_group_id
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = toset(var.subscriptions)

  management_group_id = azurerm_management_group.this.id
  subscription_id     = each.value
}
