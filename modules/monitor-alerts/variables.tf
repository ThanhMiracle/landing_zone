variable "name_prefix" {
  description = "Prefix used for naming all resources in this module."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, uat, pre-production, prod)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the monitor resources."
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

variable "email_receivers" {
  description = "List of email receivers to add to the Action Group."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = "List of webhook receivers to add to the Action Group."
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

variable "metric_alerts" {
  description = "Map of metric alerts to create. Each key becomes part of the alert resource name."
  type = map(object({
    scopes           = list(string)
    metric_namespace = string
    metric_name      = string
    aggregation      = string
    operator         = string
    threshold        = number
    severity         = optional(number, 2)
    description      = string
  }))
  default = {}
}
