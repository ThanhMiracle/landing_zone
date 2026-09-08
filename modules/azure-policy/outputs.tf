output "assignment_ids" {
  description = "Map of policy assignment IDs keyed by initiative name. Keys: 'azure_security_benchmark', 'cis_foundations'. Values are empty strings when the corresponding flag is disabled or the scope type doesn't match"
  value = {
    azure_security_benchmark = coalesce(
      try(azurerm_subscription_policy_assignment.azure_security_benchmark[0].id, ""),
      try(azurerm_resource_group_policy_assignment.azure_security_benchmark[0].id, ""),
    )
    cis_foundations = coalesce(
      try(azurerm_subscription_policy_assignment.cis_foundations[0].id, ""),
      try(azurerm_resource_group_policy_assignment.cis_foundations[0].id, ""),
    )
  }
}
