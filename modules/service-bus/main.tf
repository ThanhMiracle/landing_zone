terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Flatten all topic subscriptions into a single map keyed by
# "<topic_key>/<subscription_key>" for use with for_each.
# ---------------------------------------------------------------------------
locals {
  subscriptions = merge([
    for topic_key, topic in var.topics : {
      for sub_key, sub in lookup(topic, "subscriptions", {}) :
      "${topic_key}/${sub_key}" => merge(sub, { topic_name = topic_key })
    }
  ]...)
}

# ---------------------------------------------------------------------------
# Service Bus Namespace
# ---------------------------------------------------------------------------
resource "azurerm_servicebus_namespace" "this" {
  name                = "${var.name_prefix}-${var.environment}-sb"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------
# Queues
# ---------------------------------------------------------------------------
resource "azurerm_servicebus_queue" "this" {
  for_each = var.queues

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  lock_duration                        = each.value.lock_duration
  max_delivery_count                   = each.value.max_delivery_count
  dead_lettering_on_message_expiration = each.value.dead_lettering_on_message_expiration
  default_message_ttl                  = each.value.default_message_ttl
}

# ---------------------------------------------------------------------------
# Topics
# ---------------------------------------------------------------------------
resource "azurerm_servicebus_topic" "this" {
  for_each = var.topics

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  default_message_ttl = each.value.default_message_ttl
}

# ---------------------------------------------------------------------------
# Subscriptions (flattened from all topics)
# ---------------------------------------------------------------------------
resource "azurerm_servicebus_subscription" "this" {
  for_each = local.subscriptions

  name               = split("/", each.key)[1]
  topic_id           = azurerm_servicebus_topic.this[each.value.topic_name].id
  max_delivery_count = each.value.max_delivery_count
  lock_duration      = each.value.lock_duration
}
