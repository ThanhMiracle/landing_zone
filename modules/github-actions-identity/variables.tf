variable "name_prefix" {
  description = "Prefix used in the managed identity name."
  type        = string
}

variable "environment" {
  description = "Deployment environment used in the managed identity name and tags."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the managed identity and federated credential."
  type        = string
}

variable "location" {
  description = "Azure region for the user-assigned managed identity."
  type        = string
}

variable "container_registry_id" {
  description = "Resource ID of the ACR on which the identity receives AcrPush."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to exchange OIDC tokens, in owner/repository form."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use the owner/repository format."
  }
}

variable "github_oidc_subject" {
  description = "Exact GitHub OIDC subject allowed to exchange tokens for this identity."
  type        = string

  validation {
    condition     = startswith(var.github_oidc_subject, "repo:${var.github_repository}:")
    error_message = "github_oidc_subject must belong to github_repository."
  }
}

variable "tags" {
  description = "Additional tags to apply to the managed identity."
  type        = map(string)
  default     = {}
}
