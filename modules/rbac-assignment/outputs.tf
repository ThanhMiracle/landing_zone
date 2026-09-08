output "assignment_ids" {
  description = "Map role assignment resource IDs, keyed by assignment name."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}
