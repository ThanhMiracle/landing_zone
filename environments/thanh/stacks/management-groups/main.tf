# infra/stacks/management-groups/main.tf
# Cấu trúc CAF Management Group hierarchy:
# Tenant Root → Platform (connectivity, management, identity, security subs)
#             → Application Landing Zones (app subs)

locals {
  platform_subscription_ids = distinct(compact([
    var.connectivity_subscription_id,
    var.management_subscription_id,
    var.identity_subscription_id,
    var.security_subscription_id,
  ]))

  # A subscription can belong to only one management group. In a
  # single-subscription environment, it remains under Platform.
  application_subscription_ids = contains(local.platform_subscription_ids, var.app_subscription_id) ? [] : compact([var.app_subscription_id])
}

module "tenant_root" {
  source = "../../modules/management-group"

  name         = "root"
  display_name = "Tenant Root"
  name_prefix  = var.name_prefix
  # parent_management_group_id = null → uses Azure Tenant Root Group by default
}

module "platform" {
  source = "../../modules/management-group"

  name                       = "platform"
  display_name               = "Platform"
  name_prefix                = var.name_prefix
  parent_management_group_id = module.tenant_root.management_group_id
  subscriptions              = local.platform_subscription_ids
}

module "application" {
  source = "../../modules/management-group"

  name                       = "application"
  display_name               = "Application Landing Zones"
  name_prefix                = var.name_prefix
  parent_management_group_id = module.tenant_root.management_group_id
  subscriptions              = local.application_subscription_ids
}

# ---------------------------------------------------------------------------
# R7: Azure Policy assignments ở Management Group scope
# ASB cho Platform MG, ASB + CIS cho Application MG
# ---------------------------------------------------------------------------

module "policy_platform_mg_asb" {
  source = "../../modules/azure-policy"

  name_prefix         = var.name_prefix
  environment         = var.environment
  scope_type          = "management_group"
  management_group_id = module.platform.management_group_id

  deploy_azure_security_benchmark = true
  deploy_cis_foundations          = false
}

module "policy_application_mg_asb" {
  source = "../../modules/azure-policy"

  name_prefix         = var.name_prefix
  environment         = var.environment
  scope_type          = "management_group"
  management_group_id = module.application.management_group_id

  deploy_azure_security_benchmark = true
  deploy_cis_foundations          = false
}

module "policy_application_mg_cis" {
  source = "../../modules/azure-policy"

  name_prefix         = var.name_prefix
  environment         = var.environment
  scope_type          = "management_group"
  management_group_id = module.application.management_group_id

  deploy_azure_security_benchmark = false
  deploy_cis_foundations          = true
}
