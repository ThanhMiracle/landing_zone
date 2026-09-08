variable "assignments" {
  description = "Map of RBAC role assignments to create. Each entry specifies a principal, role definition name, and scope (resource group or individual resource)."
  type = map(object({
    principal_id         = string
    role_definition_name = string
    scope                = string
  }))
  default = {}
}
