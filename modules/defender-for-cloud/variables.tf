variable "resource_types" {
  description = <<-EOT
    Set of Azure resource types for which Microsoft Defender for Cloud
    (Standard tier) will be enabled. Each value maps to a separate
    azurerm_security_center_subscription_pricing resource via for_each.

    Supported values (case-sensitive, as required by the Azure API):
      AppServices, Arm, Containers, ContainerRegistry, Dns, KeyVaults,
      KubernetesService, OpenSourceRelationalDatabases, SqlServers,
      SqlServerVirtualMachines, StorageAccounts, VirtualMachines

    Note: enabling a plan incurs additional Azure cost.
  EOT
  type        = set(string)
  default     = ["VirtualMachines", "StorageAccounts", "KeyVaults", "AppServices"]
}
