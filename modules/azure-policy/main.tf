terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Data sources — look up built-in policy set definitions by display name
# These are resolved at plan/apply time against the real Azure tenant.
# ---------------------------------------------------------------------------

data "azurerm_policy_set_definition" "azure_security_benchmark" {
  count        = var.deploy_azure_security_benchmark ? 1 : 0
  display_name = "Microsoft Cloud Security Benchmark"
}

data "azurerm_policy_set_definition" "cis_foundations" {
  count        = var.deploy_cis_foundations ? 1 : 0
  display_name = "CIS Microsoft Azure Foundations Benchmark v2.0.0"
}

# ---------------------------------------------------------------------------
# Subscription-scope assignments
# ---------------------------------------------------------------------------

resource "azurerm_subscription_policy_assignment" "azure_security_benchmark" {
  count                = var.deploy_azure_security_benchmark && var.scope_type == "subscription" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-asb"
  display_name         = "Azure Security Benchmark — ${var.name_prefix}-${var.environment}"
  policy_definition_id = data.azurerm_policy_set_definition.azure_security_benchmark[0].id
  subscription_id      = var.subscription_id
}

resource "azurerm_subscription_policy_assignment" "cis_foundations" {
  count                = var.deploy_cis_foundations && var.scope_type == "subscription" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-cis"
  display_name         = "CIS Azure Foundations — ${var.name_prefix}-${var.environment}"
  policy_definition_id = data.azurerm_policy_set_definition.cis_foundations[0].id
  subscription_id      = var.subscription_id
}

# ---------------------------------------------------------------------------
# Resource Group-scope assignments
# ---------------------------------------------------------------------------

resource "azurerm_resource_group_policy_assignment" "azure_security_benchmark" {
  count                = var.deploy_azure_security_benchmark && var.scope_type == "resource_group" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-asb"
  display_name         = "Azure Security Benchmark — ${var.name_prefix}-${var.environment}"
  policy_definition_id = data.azurerm_policy_set_definition.azure_security_benchmark[0].id
  resource_group_id    = var.resource_group_id
}

resource "azurerm_resource_group_policy_assignment" "cis_foundations" {
  count                = var.deploy_cis_foundations && var.scope_type == "resource_group" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-cis"
  display_name         = "CIS Azure Foundations — ${var.name_prefix}-${var.environment}"
  policy_definition_id = data.azurerm_policy_set_definition.cis_foundations[0].id
  resource_group_id    = var.resource_group_id
}

# ---------------------------------------------------------------------------
# Management Group-scope assignments
# ---------------------------------------------------------------------------

resource "azurerm_management_group_policy_assignment" "azure_security_benchmark" {
  count                = var.deploy_azure_security_benchmark && var.scope_type == "management_group" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-mg-asb"
  display_name         = "Azure Security Benchmark — ${var.name_prefix} MG"
  policy_definition_id = data.azurerm_policy_set_definition.azure_security_benchmark[0].id
  management_group_id  = var.management_group_id
}

resource "azurerm_management_group_policy_assignment" "cis_foundations" {
  count                = var.deploy_cis_foundations && var.scope_type == "management_group" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-mg-cis"
  display_name         = "CIS Azure Foundations — ${var.name_prefix} MG"
  policy_definition_id = data.azurerm_policy_set_definition.cis_foundations[0].id
  management_group_id  = var.management_group_id
}
