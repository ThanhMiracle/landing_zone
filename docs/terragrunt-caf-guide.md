# Terragrunt CAF Guide: Multi-Subscription Azure Infrastructure

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Single vs Multi Subscription](#2-single-vs-multi-subscription)
3. [Prerequisites](#3-prerequisites)
4. [First Deployment: Step-by-Step](#4-first-deployment-step-by-step)
5. [Dependency Block Pattern](#5-dependency-block-pattern)
6. [Single Subscription Mode](#6-single-subscription-mode)
7. [Warning: Generated Files](#7-warning-generated-files)

---

## 1. Architecture Overview

This repository uses **Terragrunt** as the single deployment tool across all environments.

```
infra/
├── modules/              ← 32 reusable building blocks
├── platform/             ← shared infra (deployed once, all envs share)
│   ├── connectivity/     ← hub VNet, Azure Firewall, VPN, DNS Resolver
│   └── management/       ← Log Analytics, Defender for Cloud
└── environments/         ← per-environment workload stacks
    ├── dev/
    ├── test/
    ├── uat/
    ├── pre-production/
    └── prod/
```

### Deployment Flow

```
Azure Tenant
├── sub-connectivity  ← platform/connectivity/  (Hub VNet, Firewall, DNS, VPN)
├── sub-management    ← platform/management/    (Log Analytics, Defender)
├── sub-dev           ← environments/dev/       (Spoke VNet, AKS, PostgreSQL...)
├── sub-test          ← environments/test/
├── sub-uat           ← environments/uat/
├── sub-pre-prod      ← environments/pre-production/
└── sub-prod          ← environments/prod/
```

Terragrunt tự động xác định thứ tự từ `dependency` blocks:

```
platform/connectivity ──┐
platform/management   ──┤  Phase 1: parallel
                        ▼
environments/dev  ──────┐
environments/test ──────┤  Phase 2: parallel, outputs từ Phase 1 tự động flow vào
environments/uat  ──────┤
environments/prod ──────┘
```

### Architecture Layers

```
┌──────────────────────────────────────────────────────────────────┐
│  Terragrunt Layer  (infra/terragrunt.hcl + stack terragrunt.hcl) │
│  • DRY backend generation       • Dependency ordering            │
│  • Shared locals propagation    • run-all parallelism            │
└───────────────────────────┬──────────────────────────────────────┘
                            │ orchestrates
┌───────────────────────────▼──────────────────────────────────────┐
│  Terraform Deployment Roots                                       │
│  platform/connectivity/  platform/management/                     │
│  environments/dev/  environments/test/  environments/prod/ ...    │
└───────────────────────────┬──────────────────────────────────────┘
                            │ calls
┌───────────────────────────▼──────────────────────────────────────┐
│  Terraform Modules  (infra/modules/ — 32 modules)                 │
│  vnet  firewall  vnet-peering  aks  postgresql  key-vault ...     │
└───────────────────────────┬──────────────────────────────────────┘
                            │ creates
┌───────────────────────────▼──────────────────────────────────────┐
│  Azure Resources across subscriptions                             │
└──────────────────────────────────────────────────────────────────┘
```

### When to use `landing-zones/connectivity/` + `environments/`

- Your organization uses a **single Azure subscription** for all environments
- Terragrunt is **not installed** or not approved in your toolchain
- **Simple projects** with few environments and no cross-subscription networking
- Teams new to Terraform that want minimal overhead
- Quick demos or proof-of-concept deployments

```bash
# Plain Terraform workflow
cd infra/landing-zones/connectivity
terraform init -backend-config=backend.tfvars
terraform apply

cd infra/environments/dev`nterraform init -backend-config=backend.tfvars
terraform apply -var-file=terraform.tfvars
```

### When to use `platform/` + `environments/`

- Your organization has or plans **multiple Azure subscriptions** (connectivity, management, workload per env)
- You want **Microsoft CAF alignment** with subscription-per-environment isolation
- You need **automated dependency ordering** — deploy hub networking before environments
- You have **5+ environments** where DRY config matters (no repeated hub VNet IDs)
- CI/CD pipelines need to run `plan` without real infrastructure deployed (mock outputs)
- Teams ready to invest in Terragrunt for long-term operational efficiency

```bash
# Terragrunt workflow
export TF_VAR_connectivity_subscription_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export TF_VAR_management_subscription_id="yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
export TF_VAR_dev_subscription_id="zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"

cd infra
terragrunt run-all plan   # Plans all 7 stacks in correct order
terragrunt run-all apply  # Deploys all 7 stacks in correct order
```


---

## 2. Single vs Multi Subscription

Set all subscription IDs bằng cùng 1 giá trị → single-sub. Set khác nhau → multi-sub. **Không có thay đổi code nào cần thiết.**

| Mode | Config | Use case |
|------|--------|---------|
| Single subscription | Tất cả `TF_VAR_*_subscription_id` = cùng 1 giá trị | Dev, demo, POC, small projects |
| Multi subscription | Mỗi stack có subscription ID riêng | Enterprise, production, blast-radius isolation |

```bash
# Single-sub: set tất cả về 1
SINGLE_SUB="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export TF_VAR_connectivity_subscription_id="$SINGLE_SUB"
export TF_VAR_management_subscription_id="$SINGLE_SUB"
export TF_VAR_dev_subscription_id="$SINGLE_SUB"
export TF_VAR_prod_subscription_id="$SINGLE_SUB"

# Multi-sub: mỗi cái 1 subscription riêng
export TF_VAR_connectivity_subscription_id="aaa-connectivity"
export TF_VAR_management_subscription_id="bbb-management"
export TF_VAR_dev_subscription_id="ccc-dev"
export TF_VAR_prod_subscription_id="ddd-prod"
```

Terragrunt commands giống nhau cho cả 2 modes.

---

## 3. Prerequisites

Before running any Terragrunt commands, ensure the following are in place.

### Tools

| Tool | Minimum Version | Check |
|---|---|---|
| Terragrunt | `>= 0.50.0` | `terragrunt --version` |
| Terraform | `>= 1.9.0` | `terraform --version` |
| Azure CLI | any recent version | `az --version` |

```bash
# Install Terragrunt (macOS/Linux via brew)
brew install terragrunt

# Install Terragrunt (Windows via chocolatey)
choco install terragrunt

# Verify versions
terragrunt --version   # must show >= 0.50.0
terraform --version    # must show >= 1.9.0
az --version           # any version

# Authenticate Azure CLI
az login
az account show        # confirm correct tenant
```

### Azure Subscriptions

You need **4 Azure subscriptions** minimum:

| Subscription | Purpose | Terragrunt Variable |
|---|---|---|
| `sub-connectivity` | Hub VNet, Azure Firewall, DNS Resolver, VPN Gateway | `TF_VAR_connectivity_subscription_id` |
| `sub-management` | Log Analytics workspace, Azure Monitor, Defender | `TF_VAR_management_subscription_id` |
| `sub-dev` | Dev workload (Spoke VNet, AKS, PostgreSQL, etc.) | `TF_VAR_dev_subscription_id` |
| `sub-prod` | Prod workload (same structure as dev) | `TF_VAR_prod_subscription_id` |

> **Note**: If you don't have 4 subscriptions yet, see [Section 6: Single Subscription Mode](#6-single-subscription-mode).

### Azure Storage Account for Terraform State

Create a storage account in any subscription to hold all Terraform state files:

```bash
# Create resource group and storage account for tfstate
az group create \
  --name rg-tfstate \
  --location southeastasia \
  --subscription <any-subscription-id>

az storage account create \
  --name tfstate<yourprojectname> \
  --resource-group rg-tfstate \
  --location southeastasia \
  --sku Standard_LRS \
  --kind StorageV2 \
  --subscription <any-subscription-id>

az storage container create \
  --name tfstate \
  --account-name tfstate<yourprojectname>
```

> The storage account name must be globally unique. Replace `<yourprojectname>` with your project identifier (e.g., `tfstatemyproject`).

### Service Principal Permissions

The identity running Terragrunt (service principal or managed identity) needs:

- **Contributor** role on each subscription (connectivity, management, workload subs)
- **Storage Blob Data Contributor** on the tfstate storage account

---

## 4. First Deployment: Step-by-Step

### Step 1 — Set Environment Variables

Export your Azure subscription IDs as environment variables. Terragrunt reads these via `get_env()` — they are never hardcoded in any file.

```bash
# Required: platform subscriptions
export TF_VAR_connectivity_subscription_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export TF_VAR_management_subscription_id="yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"

# Required: at least one workload subscription
export TF_VAR_dev_subscription_id="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
export TF_VAR_test_subscription_id="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
export TF_VAR_uat_subscription_id="cccccccc-cccc-cccc-cccc-cccccccccccc"
export TF_VAR_pre_production_subscription_id="dddddddd-dddd-dddd-dddd-dddddddddddd"
export TF_VAR_prod_subscription_id="eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"

# On Windows PowerShell, use $env: prefix instead:
# $env:TF_VAR_connectivity_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

> **Tip**: Add these exports to a `.env` file (not committed to git) and `source .env` on each new shell session.

### Step 2 — Update `infra/terragrunt.hcl` Locals

Open `infra/terragrunt.hcl` and update the `locals` block with your project name and backend storage details:

```hcl
locals {
  # Your project identifier — used in resource naming and state storage account name
  project_name = "myproject"   # ← change this

  # Read from environment variables set in Step 1
  connectivity_subscription_id = get_env("TF_VAR_connectivity_subscription_id", "")
  management_subscription_id   = get_env("TF_VAR_management_subscription_id", "")

  common_tags = {
    Project   = local.project_name
    ManagedBy = "terraform"
  }
}

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "rg-tfstate"             # ← must match what you created in Prerequisites
    storage_account_name = "tfstate${local.project_name}"  # ← e.g. tfstatemyproject
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}
```

> The `key` is calculated automatically from the stack's folder path — you never set it manually in child stacks.

### Step 3 — Run `terragrunt run-all plan`

```bash
cd infra
terragrunt run-all plan
```

Expected output:

```
Group 1
- Module infra/platform/connectivity  [running]
- Module infra/platform/management    [running]

Group 2
- Module infra/environments/dev          [running]
- Module infra/environments/test         [running]
- Module infra/environments/uat          [running]
- Module infra/environments/pre-production [running]
- Module infra/environments/prod         [running]

Plan: X to add, 0 to change, 0 to destroy.
```

Workload stacks will show `hub_vnet_id = "mock-hub-vnet-id"` in the plan output because `platform/connectivity` has not been applied yet. This is correct behavior — mock outputs allow planning without real infrastructure.

### Step 4 — Run `terragrunt run-all apply`

```bash
cd infra
terragrunt run-all apply
```

Terragrunt automatically:
1. Deploys `platform/connectivity` and `platform/management` **in parallel** (Phase 1)
2. Waits for both platform stacks to complete
3. Deploys all `environments/*` **in parallel** (Phase 2), with real outputs from Phase 1

State files are created at these paths in your storage container:

```
tfstate container/
├── platform/connectivity/terraform.tfstate
├── platform/management/terraform.tfstate
├── environments/dev/terraform.tfstate
├── environments/test/terraform.tfstate
├── environments/uat/terraform.tfstate
├── environments/pre-production/terraform.tfstate
└── environments/prod/terraform.tfstate
```

### Destroy Order (Automatic Reverse)

```bash
cd infra
terragrunt run-all destroy
# Destroys environments first (parallel), then platform stacks — fully automatic
```

---

## 5. Dependency Block Pattern

### How Outputs Flow Between Stacks

The core value of Terragrunt dependency blocks is eliminating manual output propagation. Instead of looking up `hub_vnet_id` after applying connectivity and pasting it into a tfvars file, the workload stack reads it automatically.

```
platform/connectivity/outputs.tf          environments/dev/terragrunt.hcl
──────────────────────────────            ────────────────────────────
output "hub_vnet_id" {              ──►   dependency "connectivity" {
  value = module.hub_vnet.vnet_id           config_path = "../../platform/connectivity"
}                                         }
output "firewall_private_ip" {      ──►   inputs = {
  value = module.firewall.private_ip         hub_vnet_id         = dependency.connectivity.outputs.hub_vnet_id
}                                            firewall_private_ip = dependency.connectivity.outputs.firewall_private_ip
output "hub_resource_group_name" {  ──►      hub_resource_group_name = dependency.connectivity.outputs.hub_resource_group_name
  value = module.resource_group.name       }
}

platform/management/outputs.tf            environments/dev/terragrunt.hcl
──────────────────────────────            ────────────────────────────
output "log_analytics_workspace_id" {     dependency "management" {
  value = module.log_analytics.id           config_path = "../../platform/management"
}                                         }
                                    ──►   inputs = {
                                            log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id
                                          }
```

Only **2 values** are manually specified per workload environment:

```hcl
inputs = {
  workload_subscription_id = get_env("TF_VAR_dev_subscription_id", "")  # ← manual
  environment              = "dev"                                        # ← manual

  # Everything below is auto-populated from dependency outputs:
  connectivity_subscription_id  = local.root_locals.locals.connectivity_subscription_id
  hub_vnet_id                   = dependency.connectivity.outputs.hub_vnet_id
  firewall_private_ip           = dependency.connectivity.outputs.firewall_private_ip
  hub_resource_group_name       = dependency.connectivity.outputs.hub_resource_group_name
  log_analytics_workspace_id    = dependency.management.outputs.log_analytics_workspace_id
  name_prefix                   = local.root_locals.locals.project_name
  tags                          = merge(local.root_locals.locals.common_tags, { Environment = "dev" })
}
```

### Mock Outputs Rationale for CI/CD

In CI/CD pipelines, pull request checks run `terraform plan` before any infrastructure is deployed. Without mock outputs, the dependency block would fail because `platform/connectivity` state doesn't exist yet.

```hcl
dependency "connectivity" {
  config_path = "../../platform/connectivity"

  # Used when the dependency stack has no state yet (CI/CD, first-time plan)
  mock_outputs = {
    hub_vnet_id             = "mock-hub-vnet-id"
    firewall_private_ip     = "10.0.0.4"
    hub_resource_group_name = "mock-rg"
    dns_server_ip           = null
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  # ↑ mock outputs ONLY used for validate and plan — apply always reads real state
}
```

This means:
- **PR checks** (`terragrunt run-all plan`): use mock outputs, no Azure credentials needed for dependency lookup
- **Apply** (`terragrunt run-all apply`): reads real outputs from deployed connectivity state
- **Destroy**: reads real outputs, never uses mocks

### Full Dependency Graph

```
                ┌─────────────────────┐   ┌──────────────────────┐
                │  platform/          │   │  platform/           │
                │  connectivity/      │   │  management/         │
                │  (Phase 1)          │   │  (Phase 1)           │
                └──────────┬──────────┘   └──────────┬───────────┘
                           │  outputs                │  outputs
                           └──────────────┬──────────┘
                                          │  dependency blocks
              ┌──────────────┬────────────┼────────────┬──────────────┐
              ▼              ▼            ▼            ▼              ▼
       environments/dev/  environments/test/  environments/uat/  ...  environments/prod/
          (Phase 2)      (Phase 2)      (Phase 2)             (Phase 2)
          parallel        parallel       parallel               parallel
```

---

## 6. Single Subscription Mode

If you don't have 4 separate subscriptions — for example during development, demos, or for clients not ready for subscription separation — you can point all stacks at the same subscription.

### How to Configure

Set all `TF_VAR_*` subscription variables to the same subscription ID:

```bash
SINGLE_SUB="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

export TF_VAR_connectivity_subscription_id="$SINGLE_SUB"
export TF_VAR_management_subscription_id="$SINGLE_SUB"
export TF_VAR_dev_subscription_id="$SINGLE_SUB"
export TF_VAR_test_subscription_id="$SINGLE_SUB"
export TF_VAR_uat_subscription_id="$SINGLE_SUB"
export TF_VAR_pre_production_subscription_id="$SINGLE_SUB"
export TF_VAR_prod_subscription_id="$SINGLE_SUB"
```

No changes to any `.tf` or `terragrunt.hcl` files are needed. The provider aliases (`azurerm.workload`, `azurerm.connectivity`, `azurerm.hub`, `azurerm.spoke`) all resolve to the same subscription — cross-subscription peering becomes intra-subscription peering, which works exactly the same way.

### What changes in single-subscription mode

| Behavior | Multi-Sub | Single Sub |
|---|---|---|
| VNet peering | Cross-subscription | Intra-subscription (same sub) |
| Resource isolation | Separate subscriptions | Separate resource groups only |
| IAM blast radius | Per-subscription | All resources in one subscription |
| Cost tracking | Per-subscription | Manual tagging required |
| Terragrunt commands | Identical | Identical |

### Migrating from single to multi-subscription later

When you're ready to split into real subscriptions:

1. Create the new subscriptions in Azure
2. Export the new subscription IDs in your environment variables
3. Run `terragrunt run-all plan` to preview the changes
4. Resources will be recreated in their new subscriptions (this is a destructive migration — plan accordingly)

> **Tip**: Use single-subscription mode for non-production environments and multi-subscription only for prod if your organization is in transition.

---

## 7. Warning: Generated Files

### Never run `terraform apply` directly in `environments/` or `platform/`

> ⚠️ **Do NOT run `terraform apply` directly inside `environments/` or `platform/` directories.**
>
> Always use `terragrunt apply` or `terragrunt run-all apply`.

The Terragrunt layer generates two files in each stack directory before calling Terraform:

| Generated File | Generated By | Purpose |
|---|---|---|
| `backend.tf` | `remote_state` block in `infra/terragrunt.hcl` | Configures Azure Blob backend with correct state key |
| `provider_generated.tf` | `generate "azurerm_provider"` block in `infra/terragrunt.hcl` | Declares required Terraform and AzureRM provider versions |

### Always use Terragrunt commands

```bash
# ✅ Correct
cd infra/environments/dev
terragrunt apply

# ✅ Correct — deploy all stacks in order
cd infra
terragrunt run-all apply

# ❌ Wrong — backend.tf may not exist
cd infra/environments/dev
terraform apply

# ❌ Wrong
cd infra/platform/connectivity
terraform apply
```

### Do not commit generated files to git

`.gitignore` already excludes:

```gitignore
backend.tf
provider_generated.tf
.terragrunt-cache/
```

---

## Quick Reference

```bash
# Plan everything
cd infra && terragrunt run-all plan

# Apply everything (in dependency order)
cd infra && terragrunt run-all apply

# Apply single stack
cd infra/environments/dev && terragrunt apply

# Destroy everything (reverse dependency order)
cd infra && terragrunt run-all destroy

# Check outputs from a stack
cd infra/platform/connectivity && terragrunt output

# Validate all stacks (uses mock outputs, no Azure needed)
cd infra && terragrunt run-all validate

# Plan only platform stacks
cd infra && terragrunt run-all plan --terragrunt-include-dir platform

# Plan only environment stacks
cd infra && terragrunt run-all plan --terragrunt-include-dir environments
```

---

*This guide covers the Terragrunt CAF deployment pattern for `infra/platform/` and `infra/environments/`.*
