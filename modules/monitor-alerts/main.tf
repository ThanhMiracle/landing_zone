terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_monitor_action_group" "this" {
  name                = "${var.name_prefix}-${var.environment}-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr("${var.name_prefix}${var.environment}", 0, 12)

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name        = webhook_receiver.value.name
      service_uri = webhook_receiver.value.service_uri
    }
  }

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts

  name                = "${var.name_prefix}-${var.environment}-${each.key}-alert"
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
