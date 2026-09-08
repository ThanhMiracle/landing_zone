# infra/stacks/platform/security/main.tf
# TODO: Thêm Microsoft Sentinel, Defender for Cloud SIEM, Security Center resources tại đây
# Hiện tại chỉ deploy placeholder resource group để xác minh subscription access.

module "resource_group" {
  source = "../../../modules/resource-group"
  providers = {
    azurerm = azurerm.security
  }

  name_prefix = var.name_prefix
  environment = "${var.environment}-security"
  location    = var.location
  tags        = var.tags
}

# R11.3, R19.5: Microsoft Sentinel onboarding — conditional on deploy_sentinel flag
# Onboards the Management stack's Log Analytics workspace into Microsoft Sentinel.
# Requires deploy_sentinel = true AND a valid log_analytics_workspace_id.
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  count        = var.deploy_sentinel ? 1 : 0
  workspace_id = var.log_analytics_workspace_id
}

# R11.4, R11.7, R19.5: Defender for Cloud pricing plans — conditional on deploy_defender_plans flag
# Enables Standard tier for a configurable set of resource types.
# Uses azurerm.security provider alias scoped to the security subscription.
module "defender" {
  source = "../../../modules/defender-for-cloud"
  count  = var.deploy_defender_plans ? 1 : 0

  providers = {
    azurerm = azurerm.security
  }
}
