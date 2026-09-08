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

variable "lb_type" {
  description = "Load balancer type: 'public' (internet-facing) or 'internal' (private VNet)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "internal"], var.lb_type)
    error_message = "lb_type must be 'public' or 'internal'."
  }
}

variable "subnet_id" {
  description = "Subnet ID for the frontend IP. Required when lb_type = 'internal'."
  type        = string
  default     = null
}

variable "probe_protocol" {
  description = "Protocol for the health probe: Tcp, Http, or Https"
  type        = string
  default     = "Tcp"
}

variable "probe_port" {
  description = "Port for the health probe"
  type        = number
  default     = 80
}

variable "probe_request_path" {
  description = "Request path for Http/Https health probes (e.g. '/health')"
  type        = string
  default     = "/"
}

variable "lb_rules" {
  description = "Map of load balancing rules. Each entry specifies protocol, frontend_port, and backend_port."
  type = map(object({
    protocol      = string
    frontend_port = number
    backend_port  = number
  }))
  default = {}
}
