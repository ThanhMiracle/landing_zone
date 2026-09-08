# Naming Convention

This document defines the naming convention for all Azure resources managed by this Terraform library. All patterns are derived from the module source code and must be followed consistently across projects and environments.

---

## 1. General Pattern

```
{name_prefix}-{environment}-{resource_suffix}
```

> **Special cases** (no dashes, lowercase): Storage Account, Container Registry — see section 6.

---

## 2. Component Definitions

| Component          | Description                                                                 | Constraints                                         | Example           |
|--------------------|-----------------------------------------------------------------------------|-----------------------------------------------------|-------------------|
| `name_prefix`      | Short identifier for the project or workload. Set once per deployment.      | Lowercase letters and hyphens; keep short (≤ 10 chars recommended) | `myapp`           |
| `environment`      | Target deployment environment. One of the five standard values.             | Must be one of: `dev`, `test`, `uat`, `pre-production`, `prod` | `dev`             |
| `resource_suffix`  | Azure resource type abbreviation. Defined per module (see section 3).       | Fixed per resource type; see catalog below          | `rg`, `kv`, `vnet` |

Both `name_prefix` and `environment` are **required input variables** on every module.

---

## 3. Resource Suffix Catalog

### 3.1 Foundation

| Module              | Azure Resource                        | Naming Pattern                                      | Suffix       | Example                         |
|---------------------|---------------------------------------|-----------------------------------------------------|--------------|---------------------------------|
| `resource-group`    | `azurerm_resource_group`              | `{name_prefix}-{environment}-rg`                    | `-rg`        | `myapp-dev-rg`                  |
| `managed-identity`  | `azurerm_user_assigned_identity`      | `{name_prefix}-{environment}-id`                    | `-id`        | `myapp-dev-id`                  |

> `rbac-assignment` creates `azurerm_role_assignment` resources — no Azure name generated from this pattern (assignments use a GUID).

### 3.2 Security

| Module          | Azure Resource               | Naming Pattern                                      | Suffix   | Constraints             | Example                  |
|-----------------|------------------------------|-----------------------------------------------------|----------|-------------------------|--------------------------|
| `key-vault`     | `azurerm_key_vault`          | `{name_prefix}-{environment}-kv` (truncated to 24) | `-kv`    | Max 24 chars total      | `myapp-dev-kv`           |
| `azure-policy`  | Policy assignment (ASB)      | `{name_prefix}-{environment}-asb`                   | `-asb`   |                         | `myapp-dev-asb`          |
| `azure-policy`  | Policy assignment (CIS)      | `{name_prefix}-{environment}-cis`                   | `-cis`   |                         | `myapp-dev-cis`          |

### 3.3 Networking

| Module             | Azure Resource                       | Naming Pattern                                          | Suffix          | Example                          |
|--------------------|--------------------------------------|---------------------------------------------------------|-----------------|----------------------------------|
| `vnet`             | `azurerm_virtual_network`            | `{name_prefix}-{environment}-vnet`                      | `-vnet`         | `myapp-dev-vnet`                 |
| `nsg`              | `azurerm_network_security_group`     | `{name_prefix}-{environment}-nsg`                       | `-nsg`          | `myapp-dev-nsg`                  |
| `nat-gateway`      | `azurerm_nat_gateway`                | `{name_prefix}-{environment}-natgw`                     | `-natgw`        | `myapp-dev-natgw`                |
| `nat-gateway`      | `azurerm_public_ip` (NAT)            | `{name_prefix}-{environment}-nat-pip`                   | `-nat-pip`      | `myapp-dev-nat-pip`              |
| `bastion`          | `azurerm_bastion_host`               | `{name_prefix}-{environment}-bas`                       | `-bas`          | `myapp-dev-bas`                  |
| `bastion`          | `azurerm_public_ip` (Bastion)        | `{name_prefix}-{environment}-bastion-pip`               | `-bastion-pip`  | `myapp-dev-bastion-pip`          |
| `private-endpoint` | `azurerm_private_endpoint`           | `{name_prefix}-{environment}-pep`                       | `-pep`          | `myapp-dev-pep`                  |
| `private-endpoint` | Private service connection           | `{name_prefix}-{environment}-psc`                       | `-psc`          | `myapp-dev-psc`                  |
| `private-endpoint` | DNS zone VNet link                   | `{name_prefix}-{environment}-dns-link`                  | `-dns-link`     | `myapp-dev-dns-link`             |

> Subnets are named by the **key** used in the `subnets` map variable — not by the general pattern. Example: `"app"`, `"db"`, `"AzureBastionSubnet"`.

### 3.4 Monitoring & Observability

| Module                | Azure Resource                          | Naming Pattern                                        | Suffix    | Example                         |
|-----------------------|-----------------------------------------|-------------------------------------------------------|-----------|---------------------------------|
| `log-analytics`       | `azurerm_log_analytics_workspace`       | `{name_prefix}-{environment}-log`                     | `-log`    | `myapp-dev-log`                 |
| `app-insights`        | `azurerm_application_insights`          | `{name_prefix}-{environment}-appi`                    | `-appi`   | `myapp-dev-appi`                |
| `monitor-alerts`      | `azurerm_monitor_action_group`          | `{name_prefix}-{environment}-ag`                      | `-ag`     | `myapp-dev-ag`                  |
| `monitor-alerts`      | `azurerm_monitor_metric_alert`          | `{name_prefix}-{environment}-{alert_key}-alert`       | varies    | `myapp-dev-cpu-alert`           |
| `diagnostic-settings` | `azurerm_monitor_diagnostic_setting`    | Caller-supplied `name` variable                       | n/a       | `diag-kv`, `diag-storage`       |

### 3.5 Storage

| Module            | Azure Resource                  | Naming Pattern                                      | Suffix | Constraints                    | Example            |
|-------------------|---------------------------------|-----------------------------------------------------|--------|--------------------------------|--------------------|
| `storage-account` | `azurerm_storage_account`       | `{name_prefix}{environment}st` (no dashes)          | `st`   | No dashes; lowercase; max 24   | `myappdevst`       |
| `storage-account` | `azurerm_storage_container`     | Named by the key in the `containers` map variable   | n/a    | Lowercase; no dashes/underscores | `raw`, `processed` |

### 3.6 Compute

| Module               | Azure Resource              | Naming Pattern                                    | Suffix   | Example                        |
|----------------------|-----------------------------|---------------------------------------------------|----------|--------------------------------|
| `container-registry` | `azurerm_container_registry`| `{name_prefix}{environment}acr` (no dashes)       | `acr`    | `myappdevacr`                  |
| `function-app`       | `azurerm_service_plan`      | `{name_prefix}-{environment}-asp`                 | `-asp`   | `myapp-dev-asp`                |
| `function-app`       | `azurerm_linux_function_app`| `{name_prefix}-{environment}-func`                | `-func`  | `myapp-dev-func`               |
| `app-service`        | `azurerm_service_plan`      | `{name_prefix}-{environment}-asp`                 | `-asp`   | `myapp-dev-asp`                |
| `app-service`        | `azurerm_linux_web_app`     | `{name_prefix}-{environment}-app`                 | `-app`   | `myapp-dev-app`                |

> If both `function-app` and `app-service` are deployed together, they will each create a Service Plan named `*-asp`. Deploy them in separate resource groups, or override as needed to avoid conflicts.

### 3.7 Database

| Module                  | Azure Resource                               | Naming Pattern                                | Suffix   | Example                       |
|-------------------------|----------------------------------------------|-----------------------------------------------|----------|-------------------------------|
| `postgresql-flexible`   | `azurerm_postgresql_flexible_server`          | `{name_prefix}-{environment}-psql`            | `-psql`  | `myapp-dev-psql`              |
| `postgresql-flexible`   | `azurerm_postgresql_flexible_server_database` | Named by the key in the `databases` map       | n/a      | `appdb`, `auditdb`            |

### 3.8 Messaging

| Module        | Azure Resource                  | Naming Pattern                            | Suffix  | Example                  |
|---------------|---------------------------------|-------------------------------------------|---------|--------------------------|
| `service-bus` | `azurerm_servicebus_namespace`  | `{name_prefix}-{environment}-sb`          | `-sb`   | `myapp-dev-sb`           |
| `service-bus` | Queues and topics               | Named by the key in the respective map variable | n/a | `orders`, `notifications` |

### 3.9 API Management

| Module  | Azure Resource           | Naming Pattern                             | Suffix   | Example             |
|---------|--------------------------|--------------------------------------------|----------|---------------------|
| `apim`  | `azurerm_api_management` | `{name_prefix}-{environment}-apim`         | `-apim`  | `myapp-dev-apim`    |

---

## 4. Tag Standards

Tags are applied via `merge()` in every module's `main.tf`:

```hcl
tags = merge(
  {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  },
  var.tags  # caller-supplied optional tags
)
```

### Required Tags (auto-applied by every module)

| Tag Key       | Value                        | Description                                   |
|---------------|------------------------------|-----------------------------------------------|
| `Project`     | `var.name_prefix`            | Identifies the project or workload             |
| `Environment` | `var.environment`            | Deployment environment (`dev`, `prod`, etc.)  |
| `ManagedBy`   | `"terraform"` (hardcoded)    | Indicates infrastructure-as-code ownership    |

### Optional Tags (passed via `var.tags`)

| Tag Key      | Example Value     | Description                                 |
|--------------|-------------------|---------------------------------------------|
| `Owner`      | `"platform-team"` | Team or individual responsible for resource |
| `CostCenter` | `"CC-12345"`      | For cost allocation and billing reports     |

Any additional key-value pairs can be passed via `var.tags` — they will be merged with the mandatory set.

> All modules expose `variable "tags" { type = map(string); default = {} }`.

---

## 5. Concrete Examples — Project "myapp", Environment "dev"

| Resource Type            | Module               | Resulting Azure Resource Name     |
|--------------------------|----------------------|-----------------------------------|
| Resource Group           | `resource-group`     | `myapp-dev-rg`                    |
| Managed Identity         | `managed-identity`   | `myapp-dev-id`                    |
| Key Vault                | `key-vault`          | `myapp-dev-kv`                    |
| Storage Account          | `storage-account`    | `myappdevst`                      |
| Log Analytics Workspace  | `log-analytics`      | `myapp-dev-log`                   |
| Application Insights     | `app-insights`       | `myapp-dev-appi`                  |
| Virtual Network          | `vnet`               | `myapp-dev-vnet`                  |
| Network Security Group   | `nsg`                | `myapp-dev-nsg`                   |
| NAT Gateway              | `nat-gateway`        | `myapp-dev-natgw`                 |
| NAT Public IP            | `nat-gateway`        | `myapp-dev-nat-pip`               |
| Bastion Host             | `bastion`            | `myapp-dev-bas`                   |
| Bastion Public IP        | `bastion`            | `myapp-dev-bastion-pip`           |
| Private Endpoint         | `private-endpoint`   | `myapp-dev-pep`                   |
| Container Registry       | `container-registry` | `myappdevacr`                     |
| App Service Plan         | `function-app`       | `myapp-dev-asp`                   |
| Function App             | `function-app`       | `myapp-dev-func`                  |
| Web App                  | `app-service`        | `myapp-dev-app`                   |
| PostgreSQL Server        | `postgresql-flexible`| `myapp-dev-psql`                  |
| Service Bus Namespace    | `service-bus`        | `myapp-dev-sb`                    |
| API Management           | `apim`               | `myapp-dev-apim`                  |
| Monitor Action Group     | `monitor-alerts`     | `myapp-dev-ag`                    |
| Policy Assignment (ASB)  | `azure-policy`       | `myapp-dev-asb`                   |
| Policy Assignment (CIS)  | `azure-policy`       | `myapp-dev-cis`                   |

---

## 6. Special Cases

### 6.1 Storage Account — no dashes, max 24 characters

Azure Storage Account names must be globally unique, lowercase, alphanumeric only, 3–24 characters. The module applies this automatically:

```hcl
name = substr(lower("${var.name_prefix}${var.environment}st"), 0, 24)
```

| `name_prefix` | `environment`    | Result              |
|---------------|------------------|---------------------|
| `myapp`       | `dev`            | `myappdevst`        |
| `myapp`       | `prod`           | `myappprodst`       |
| `longproject` | `pre-production` | `longprojectpre-pro` (truncated) |

> Keep `name_prefix` short to avoid unintended truncation and naming collisions.

### 6.2 Key Vault — max 24 characters

```hcl
name = substr("${var.name_prefix}-${var.environment}-kv", 0, 24)
```

| `name_prefix` | `environment`    | Result (truncated to 24)     |
|---------------|------------------|------------------------------|
| `myapp`       | `dev`            | `myapp-dev-kv` (13 chars)    |
| `myapp`       | `pre-production` | `myapp-pre-production-kv` (25 → 24 truncated, suffix `-kv` preserved) |
| `longprefix`  | `pre-production` | `longprefix-pre-producti` (suffix `-kv` lost) |

> **Recommendation:** Keep `name_prefix` ≤ 8 characters to preserve the `-kv` suffix in all environments.

### 6.3 Container Registry — no dashes, lowercase

```hcl
name = lower("${var.name_prefix}${var.environment}acr")
```

| `name_prefix` | `environment` | Result           |
|---------------|---------------|------------------|
| `myapp`       | `dev`         | `myappdevacr`    |
| `myapp`       | `prod`        | `myappprodacr`   |

### 6.4 Monitor Action Group — `short_name` truncation

Azure Action Groups require a `short_name` of at most 12 characters:

```hcl
short_name = substr("${var.name_prefix}${var.environment}", 0, 12)
```

This is an internal display field only and does not affect the resource `name`.

---

## 7. Summary Table — All Suffixes

| Suffix         | Resource Type                             | Module               |
|----------------|-------------------------------------------|----------------------|
| `-rg`          | Resource Group                            | `resource-group`     |
| `-id`          | User Assigned Managed Identity            | `managed-identity`   |
| `-kv`          | Key Vault                                 | `key-vault`          |
| `-asb`         | Azure Security Benchmark Policy           | `azure-policy`       |
| `-cis`         | CIS Foundations Policy                    | `azure-policy`       |
| `-vnet`        | Virtual Network                           | `vnet`               |
| `-nsg`         | Network Security Group                    | `nsg`                |
| `-natgw`       | NAT Gateway                               | `nat-gateway`        |
| `-nat-pip`     | Public IP for NAT Gateway                 | `nat-gateway`        |
| `-bas`         | Bastion Host                              | `bastion`            |
| `-bastion-pip` | Public IP for Bastion                     | `bastion`            |
| `-pep`         | Private Endpoint                          | `private-endpoint`   |
| `-psc`         | Private Service Connection                | `private-endpoint`   |
| `-dns-link`    | Private DNS Zone VNet Link                | `private-endpoint`   |
| `-log`         | Log Analytics Workspace                   | `log-analytics`      |
| `-appi`        | Application Insights                      | `app-insights`       |
| `-ag`          | Monitor Action Group                      | `monitor-alerts`     |
| `st`           | Storage Account *(no dash)*               | `storage-account`    |
| `acr`          | Container Registry *(no dash)*            | `container-registry` |
| `-asp`         | App Service Plan                          | `function-app` / `app-service` |
| `-func`        | Function App                              | `function-app`       |
| `-app`         | Web App (App Service)                     | `app-service`        |
| `-psql`        | PostgreSQL Flexible Server                | `postgresql-flexible`|
| `-sb`          | Service Bus Namespace                     | `service-bus`        |
| `-apim`        | API Management                            | `apim`               |
| `-aks`         | AKS Cluster                               | `aks`                |
| `-cosmos`      | Cosmos DB Account                         | `cosmos-db`          |
| `-redis`       | Azure Cache for Redis                     | `redis-cache`        |
| `-lb`          | Azure Load Balancer                       | `load-balancer`      |
| `-{name}-vm`   | Linux Virtual Machine                     | `virtual-machine`    |
| `-{name}-nic`  | Network Interface                         | `virtual-machine`    |
| `-fw`          | Azure Firewall                            | `firewall`           |
| `-vpngw`       | VPN Gateway                               | `vpn-gateway`        |
| `-dnsresolver` | DNS Private Resolver                      | `dns-resolver`       |
| `-rt`          | Route Table                               | `route-table`        |

### 3.10 Advanced Compute

| Module             | Azure Resource                       | Naming Pattern                                          | Suffix           | Example                          |
|--------------------|--------------------------------------|---------------------------------------------------------|------------------|----------------------------------|
| `aks`              | `azurerm_kubernetes_cluster`         | `{name_prefix}-{environment}-aks`                       | `-aks`           | `myapp-dev-aks`                  |
| `virtual-machine`  | `azurerm_linux_virtual_machine`      | `{name_prefix}-{environment}-{name}-vm`                 | `-{name}-vm`     | `myapp-dev-web-vm`               |
| `virtual-machine`  | `azurerm_network_interface`          | `{name_prefix}-{environment}-{name}-nic`                | `-{name}-nic`    | `myapp-dev-web-nic`              |
| `load-balancer`    | `azurerm_lb`                         | `{name_prefix}-{environment}-lb`                        | `-lb`            | `myapp-dev-lb`                   |

### 3.11 Advanced Data

| Module        | Azure Resource              | Naming Pattern                              | Suffix    | Example                   |
|---------------|-----------------------------|---------------------------------------------|-----------|---------------------------|
| `cosmos-db`   | `azurerm_cosmosdb_account`  | `{name_prefix}-{environment}-cosmos`        | `-cosmos` | `myapp-dev-cosmos`        |
| `redis-cache` | `azurerm_redis_cache`       | `{name_prefix}-{environment}-redis`         | `-redis`  | `myapp-dev-redis`         |

### 3.12 Advanced Networking

| Module          | Azure Resource                         | Naming Pattern                                     | Suffix         | Example                        |
|-----------------|----------------------------------------|----------------------------------------------------|----------------|--------------------------------|
| `firewall`      | `azurerm_firewall`                     | `{name_prefix}-{environment}-fw`                   | `-fw`          | `myapp-dev-fw`                 |
| `vpn-gateway`   | `azurerm_virtual_network_gateway`      | `{name_prefix}-{environment}-vpngw`                | `-vpngw`       | `myapp-dev-vpngw`              |
| `dns-resolver`  | `azurerm_private_dns_resolver`         | `{name_prefix}-{environment}-dnsresolver`          | `-dnsresolver` | `myapp-dev-dnsresolver`        |
| `route-table`   | `azurerm_route_table`                  | `{name_prefix}-{environment}-rt`                   | `-rt`          | `myapp-dev-rt`                 |
