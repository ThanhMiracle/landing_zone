variable "name" {
  description = "Name of the diagnostic setting."
  type        = string
}

variable "target_resource_id" {
  description = "The ID of the resource to attach the diagnostic setting to."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics Workspace to send logs and metrics to."
  type        = string
}

variable "log_categories" {
  description = "List of log category names to enable (e.g. [\"AuditEvent\", \"AzurePolicyEvaluationDetails\"])."
  type        = list(string)
  default     = []
}

variable "metric_categories" {
  description = "List of metric category names to enable (e.g. [\"AllMetrics\"])."
  type        = list(string)
  default     = ["AllMetrics"]
}
