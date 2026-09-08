# infra/stacks/platform/identity/main.tf
# TODO: Thêm Entra ID, AD DS, Conditional Access resources tại đây
# Hiện tại chỉ deploy placeholder resource group để xác minh subscription access.

module "resource_group" {
  source = "../../../modules/resource-group"
  providers = {
    azurerm = azurerm.identity
  }

  # Module tạo tên: {name_prefix}-{environment}-rg
  # Truyền environment = "${var.environment}-identity" để kết quả là:
  #   {name_prefix}-{environment}-identity-rg
  name_prefix = var.name_prefix
  environment = "${var.environment}-identity"
  location    = var.location
  tags        = var.tags
}

# R10: Azure AD Domain Services (conditional — enabled by deploy_identity_ds flag)
resource "azurerm_active_directory_domain_service" "this" {
  count = var.deploy_identity_ds ? 1 : 0

  provider            = azurerm.identity
  name                = "${var.name_prefix}-${var.environment}-adds"
  location            = var.location
  resource_group_name = module.resource_group.name

  domain_name = var.adds_domain_name
  sku         = var.adds_sku

  initial_replica_set {
    subnet_id = var.adds_subnet_id
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}
