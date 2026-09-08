# Module: defender-for-cloud

Enables **Microsoft Defender for Cloud** (Standard tier) at the subscription level
for a configurable set of resource types.

---

## ⚠️ Permission Requirements

This module operates at the **subscription scope** and requires one of the following
Azure built-in roles assigned on the subscription:

| Role | Notes |
|------|-------|
| **Owner** | Full control; includes Security Admin permissions |
| **Security Admin** | Can change security policies and dismiss security alerts |
| **Contributor** | **Not sufficient** — cannot modify Security Center pricing tier |

The Terraform principal (service principal or managed identity used to run
`terraform apply`) must hold one of the roles above **at subscription level**.

To assign the role via CLI:
```bash
# Replace <principal-id> and <subscription-id> with real values
az role assignment create \
  --assignee <principal-id> \
  --role "Security Admin" \
  --scope /subscriptions/<subscription-id>
```

---

## Usage

```hcl
module "defender_for_cloud" {
  source = "../../modules/defender-for-cloud"

  # Enable Defender for the four default resource types
  resource_types = ["VirtualMachines", "StorageAccounts", "KeyVaults", "AppServices"]
}
```

To extend coverage:
```hcl
module "defender_for_cloud" {
  source = "../../modules/defender-for-cloud"

  resource_types = [
    "VirtualMachines",
    "StorageAccounts",
    "KeyVaults",
    "AppServices",
    "Containers",
    "SqlServers",
  ]
}
```

---

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_types` | `set(string)` | `["VirtualMachines", "StorageAccounts", "KeyVaults", "AppServices"]` | Set of resource types for which Defender Standard tier is enabled |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `enabled_plans` | `list(string)` | List of resource type names that were enabled by this module |

---

## Supported Resource Types

The following values are accepted by the Azure API for `resource_type`
(values are case-sensitive):

| Value | Defender Plan |
|-------|--------------|
| `AppServices` | Defender for App Service |
| `Arm` | Defender for Azure Resource Manager |
| `Containers` | Defender for Containers |
| `ContainerRegistry` | Defender for Container Registries (legacy) |
| `Dns` | Defender for DNS |
| `KeyVaults` | Defender for Key Vault |
| `KubernetesService` | Defender for Kubernetes (legacy) |
| `OpenSourceRelationalDatabases` | Defender for open-source relational DBs |
| `SqlServers` | Defender for SQL on Azure VMs |
| `SqlServerVirtualMachines` | Defender for SQL on machines |
| `StorageAccounts` | Defender for Storage |
| `VirtualMachines` | Defender for Servers |

---

## Cost Impact

Enabling Defender plans incurs **additional Azure charges**. Pricing is
calculated per resource (e.g. per server/hour, per storage account/month).
Review [Azure Defender for Cloud pricing](https://azure.microsoft.com/en-us/pricing/details/defender-for-cloud/)
before enabling plans in production environments.

---

## Notes

- This module does **not** create any resource group or naming-convention resources —
  it operates purely at the subscription level.
- Disabling a plan (removing a type from `resource_types`) will revert that
  resource type to the **Free** tier.
- The `azurerm_security_center_subscription_pricing` resource manages one plan
  per resource type; Terraform uses `for_each` so individual plans can be
  toggled without affecting others.
