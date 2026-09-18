variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags merged with mandatory tags"
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster (e.g. '1.29'). Leave null to use the latest."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Whether to deploy a private AKS cluster (API server not publicly accessible)"
  type        = bool
  default     = false
}

variable "identity_id" {
  description = "Optional user-assigned identity resource ID for the AKS control plane."
  type        = string
  default     = null
}

variable "outbound_type" {
  description = "Outbound routing mode for the AKS cluster."
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer or userDefinedRouting."
  }
}

variable "enable_azure_ad_rbac" {
  description = "Whether to enable Azure AD-integrated RBAC for the cluster"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for the OMS agent add-on. Set to null to disable."
  type        = string
  default     = null
}

variable "system_node_pool" {
  description = "Configuration for the system (default) node pool"
  type = object({
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
  })
  default = {
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    min_count           = 1
    max_count           = 3
    enable_auto_scaling = false
  }
}

variable "user_node_pools" {
  description = "Map of additional user node pools. Key is used as the node pool name (max 12 chars, lowercase)."
  type = map(object({
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
  }))
  default = {}
}

variable "subnet_id" {
  description = "Resource ID của subnet dành cho system node pool. Khi set, AKS nodes được deploy vào subnet này (VNet integration). Để null để dùng default VNet Azure."
  type        = string
  default     = null
}
