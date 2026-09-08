# infra/stacks/platform/management/variables.tf
# Variables for the Management platform stack.
# All values are passed in from terragrunt.hcl via env.hcl.

variable "subscription_id" {
  description = "Azure Subscription ID for the management platform subscription. Used by the azurerm.management provider alias."
  type        = string
}

variable "name_prefix" {
  description = "Project name prefix used in all resource names: {name_prefix}-{environment}-{suffix}. Must be lowercase, max 10 characters."
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod). Combined with name_prefix to form resource names."
  type        = string
}

variable "location" {
  description = "Azure region where all resources in this stack will be created (e.g. southeastasia, eastasia)."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with mandatory stack tags (Project, Environment, ManagedBy). Passed from env.hcl common_tags."
  type        = map(string)
  default     = {}
}

variable "deploy_defender" {
  description = "Whether to deploy Microsoft Defender for Cloud in this management subscription. Set to true only when the subscription ID is configured."
  type        = bool
  default     = false
}

variable "log_analytics_retention_days" {
  description = "Number of days to retain logs in the Log Analytics workspace. Valid range: 30–730 days."
  type        = number
  default     = 30
}
