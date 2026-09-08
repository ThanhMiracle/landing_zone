# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to produce the namespace name."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the Service Bus Namespace."
  type        = string
}

variable "location" {
  description = "Azure region for the Service Bus Namespace (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Namespace
# ---------------------------------------------------------------------------

variable "sku" {
  description = "SKU tier for the Service Bus Namespace. Allowed values: 'Basic', 'Standard', 'Premium'. Topics are only supported on Standard and Premium."
  type        = string
  default     = "Standard"
}

# ---------------------------------------------------------------------------
# Queues
# ---------------------------------------------------------------------------

variable "queues" {
  description = <<-EOT
    Map of Service Bus queues to create. Key = queue name.
    - lock_duration: ISO 8601 duration for the message lock. E.g. 'PT1M' (1 minute).
    - max_delivery_count: Maximum number of delivery attempts before dead-lettering. Range: 1–2000.
    - dead_lettering_on_message_expiration: Move messages to dead-letter sub-queue when TTL expires.
    - default_message_ttl: ISO 8601 duration for message time-to-live. E.g. 'P14D' (14 days). Null uses namespace default.
  EOT
  type = map(object({
    lock_duration                        = string
    max_delivery_count                   = number
    dead_lettering_on_message_expiration = bool
    default_message_ttl                  = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Topics & Subscriptions
# ---------------------------------------------------------------------------

variable "topics" {
  description = <<-EOT
    Map of Service Bus topics to create. Key = topic name. Only supported on Standard and Premium SKUs.
    - default_message_ttl: ISO 8601 duration for message time-to-live. E.g. 'P14D' (14 days).
    - subscriptions: Map of subscriptions on this topic. Key = subscription name.
        - lock_duration: ISO 8601 duration for the message lock. E.g. 'PT1M' (1 minute).
        - max_delivery_count: Maximum number of delivery attempts before dead-lettering. Range: 1–2000.
  EOT
  type = map(object({
    default_message_ttl = string
    subscriptions = map(object({
      lock_duration      = string
      max_delivery_count = number
    }))
  }))
  default = {}
}
