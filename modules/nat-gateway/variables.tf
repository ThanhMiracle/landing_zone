variable "name_prefix" {
  description = "Prefix used in all resource names, e.g. 'myapp'"
  type        = string
}

variable "environment" {
  description = "Deployment environment, e.g. 'dev', 'prod'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for all resources in this module"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory tags (Project, Environment, ManagedBy)"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Resource ID of the subnet to associate the NAT Gateway with"
  type        = string
}

variable "idle_timeout_in_minutes" {
  description = "The idle timeout in minutes for the NAT Gateway. Must be between 4 and 120."
  type        = number
  default     = 10
}
