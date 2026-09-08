terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  common_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "azurerm_kubernetes_cluster" "this" {
  name                    = "${var.name_prefix}-${var.environment}-aks"
  resource_group_name     = var.resource_group_name
  location                = var.location
  dns_prefix              = "${var.name_prefix}-${var.environment}"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled

  role_based_access_control_enabled = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.system_node_pool.vm_size
    node_count           = var.system_node_pool.enable_auto_scaling ? null : var.system_node_pool.node_count
    min_count            = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.min_count : null
    max_count            = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.max_count : null
    auto_scaling_enabled = var.system_node_pool.enable_auto_scaling
    # R6: VNet integration — khi subnet_id = null AKS dùng default VNet (backward compatible)
    vnet_subnet_id       = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_rbac ? [1] : []
    content {
      azure_rbac_enabled = true
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = local.common_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  auto_scaling_enabled  = each.value.enable_auto_scaling

  tags = local.common_tags
}
