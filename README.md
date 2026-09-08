# Azure CAF Landing Zone Enterprise — IaC Library

Thư viện Terraform + Terragrunt cho **Azure Cloud Adoption Framework (CAF) Landing Zone** cấp doanh nghiệp — hỗ trợ multi-subscription, feature flag driven, và triển khai toàn bộ environment bằng một lệnh duy nhất.

---

## Mục Lục

1. [Cấu Trúc Repository](#1-cấu-trúc-repository)
2. [Yêu Cầu Hệ Thống](#2-yêu-cầu-hệ-thống)
3. [Getting Started](#3-getting-started)
4. [Quản Lý Environment](#4-quản-lý-environment)
5. [Feature Flags](#5-feature-flags)
6. [Thứ Tự Triển Khai](#6-thứ-tự-triển-khai)
7. [State File Layout](#7-state-file-layout)
8. [Module Catalog](#8-module-catalog)
9. [Bảo Mật Mặc Định](#9-bảo-mật-mặc-định)
10. [Tài Liệu](#10-tài-liệu)

---

## 1. Cấu Trúc Repository

```
infra/
├── terragrunt.hcl                          ← Root config: backend + provider version
│
├── modules/                                ← 33 reusable Terraform modules (KHÔNG THAY ĐỔI)
│   ├── aks/
│   ├── apim/
│   ├── app-insights/
│   ├── app-service/
│   ├── azure-policy/
│   ├── bastion/
│   ├── container-registry/
│   ├── cosmos-db/
│   ├── defender-for-cloud/
│   ├── diagnostic-settings/
│   ├── dns-resolver/
│   ├── firewall/
│   ├── function-app/
│   ├── key-vault/
│   ├── load-balancer/
│   ├── log-analytics/
│   ├── managed-identity/
│   ├── management-group/                   ← MODULE MỚI: CAF Management Group hierarchy
│   ├── monitor-alerts/
│   ├── nat-gateway/
│   ├── nsg/
│   ├── postgresql-flexible/
│   ├── private-endpoint/
│   ├── rbac-assignment/
│   ├── redis-cache/
│   ├── resource-group/
│   ├── route-table/
│   ├── service-bus/
│   ├── storage-account/
│   ├── virtual-machine/
│   ├── vnet/
│   ├── vnet-peering/
│   └── vpn-gateway/
│
├── scripts/                                ← Utility scripts
│   └── setup-junctions.ps1                ← (Windows) Tái tạo junction points sau clone
│
├── stacks/                                 ← Deployment units — CAF Landing Zone
│   ├── management-groups/                  ← Tier 0: chạy một lần cho toàn tenant
│   │   └── terragrunt.hcl
│   │
│   ├── governance/                         ← Tenant/cross-subscription governance
│   │   └── rbac/                           ← RBAC cross-subscription assignments (Sprint 3)
│   │       ├── terragrunt.hcl
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── platform/                           ← Tier 1: platform subscriptions
│   │   ├── connectivity/                   ← Hub VNet, Firewall, VPN Gateway, DNS
│   │   │   ├── terragrunt.hcl
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── hub-network.tf
│   │   │   ├── firewall.tf
│   │   │   ├── vpn.tf
│   │   │   └── dns.tf
│   │   ├── management/                     ← Log Analytics, Defender for Cloud
│   │   │   ├── terragrunt.hcl
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── observability.tf
│   │   ├── identity/                       ← Scaffold: Entra ID, AD DS (tắt mặc định)
│   │   │   ├── terragrunt.hcl
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── security/                       ← Scaffold: Sentinel, Security Center (tắt mặc định)
│   │       ├── terragrunt.hcl
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── application/                        ← Tier 2–3: application workloads
│       ├── baseline/                       ← Tier 2: Spoke VNet, KV, MI, Policy
│       │   ├── terragrunt.hcl
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── networking.tf
│       │   ├── compute.tf
│       │   └── database.tf
│       └── workloads/                      ← Tier 3: generic workload templates
│           ├── aks/
│           ├── postgresql/
│           ├── vm-bastion/
│           ├── redis/
│           └── service-bus/
│
└── environments/                           ← Entry point — chỉ chứa .hcl files
    ├── dev/
    │   ├── env.hcl                         ← Nguồn sự thật DUY NHẤT cho environment dev
    │   └── terragrunt.hcl                  ← Điểm khởi chạy run-all
    ├── staging/
    ├── prod/
    ├── test/
    ├── uat/
    └── pre-production/
```

> **Ràng buộc quan trọng:**
> - `modules/` giữ nguyên 100% — không sửa, không xóa bất kỳ file nào.
> - `environments/{env}/` chỉ chứa `.hcl` files — không có `.tf` files.
> - Mỗi stack trong `stacks/` là deployment unit độc lập với state riêng biệt.

---

## 2. Yêu Cầu Hệ Thống

| Công cụ | Phiên bản tối thiểu | Kiểm tra |
|---------|---------------------|----------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.9.0` | `terraform version` |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | `>= 0.55.0` | `terragrunt --version` |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | `>= 2.60.0` | `az version` |
| Git | `>= 2.x` | `git --version` |

**Quyền Azure cần thiết:**
- `Contributor` + `User Access Administrator` ở subscription scope (cho từng subscription được deploy)
- `Management Group Contributor` ở tenant root (chỉ cần khi `deploy_management_groups = true`)

**Đăng nhập trước khi chạy:**

```bash
az login
az account set --subscription "<APP_SUBSCRIPTION_ID>"
```

---

## 3. Getting Started

### Quick Start

1. Clone repo và cd vào thư mục infra:
   ```bash
   git clone <repo-url>
   cd infra
   ```
2. **(Windows only)** Tái tạo junction points sau khi clone:
   ```powershell
   # Chạy với quyền Administrator
   .\scripts\setup-junctions.ps1
   ```
3. Cấu hình environment: chỉnh sửa `environments/<env>/env.hcl` — đây là file cấu hình DUY NHẤT.
4. Điền Subscription IDs trong `env.hcl` (xem Bước 3 bên dưới).
5. Bật các stack cần thiết bằng feature flags (xem [bảng Feature Flags](#5-feature-flags)).
6. Validate (không cần Azure credentials):
   ```bash
   cd environments/dev
   TERRAGRUNT_USE_LOCAL_BACKEND=true terragrunt run-all validate
   ```
7. Apply:
   ```bash
   terragrunt run-all apply
   ```

---

### Bước 1 — Clone repository và vào thư mục infra

```bash
git clone <repo-url>
cd infra
```

> **(Windows only)** Git không track Windows junction points. Sau khi clone, chạy script để tái tạo junctions:
> ```powershell
> # Mở PowerShell với quyền Administrator, sau đó:
> .\scripts\setup-junctions.ps1
> ```
> Script tạo các junction `environments/<env>/stacks → stacks/` cho cả 6 environments. Xem [`scripts/setup-junctions.ps1`](scripts/setup-junctions.ps1) để biết chi tiết.

### Bước 2 — Copy file cấu hình environment

Mỗi environment được cấu hình hoàn toàn bằng một file `env.hcl` duy nhất.

```bash
# Ví dụ: tạo environment dev mới từ template
cp environments/dev/env.hcl environments/<your-env>/env.hcl
```

### Bước 3 — Điền Subscription IDs

Mở `environments/<your-env>/env.hcl` và điền các giá trị thực tế:

```hcl
locals {
  # Thông tin cơ bản
  name_prefix = "myproject"   # lowercase, tối đa 10 ký tự
  environment = "dev"
  location    = "southeastasia"

  # Subscription IDs — điền UUID từ Azure Portal
  connectivity_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  management_subscription_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  identity_subscription_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  security_subscription_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  app_subscription_id          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

> **Lưu ý:** Để thống nhất single-subscription (dev/test), đặt tất cả subscription IDs cùng một giá trị.  
> Để trống `""` cho CI validate — không cần Azure credentials thật.

### Bước 4 — Bật/tắt feature flags theo nhu cầu

```hcl
locals {
  # Platform flags
  deploy_management_groups = true
  deploy_connectivity      = true
  deploy_management        = true
  deploy_identity          = false   # scaffold, tắt mặc định
  deploy_security          = false   # scaffold, tắt mặc định

  # Connectivity sub-flags
  deploy_firewall     = true
  deploy_vpn_gateway  = false   # tốn ~30–60 phút để tạo
  deploy_dns_resolver = false
  deploy_bastion      = false   # Azure Bastion trong hub VNet

  # Application workload flags
  deploy_aks          = true
  deploy_postgresql   = true
  deploy_redis        = false
  deploy_vm_bastion   = false   # VM Bastion workload trong spoke (R1)
  deploy_service_bus  = false   # Service Bus Namespace workload (R2)
  # deploy_apim = false         # DEPRECATED — dùng deploy_service_bus
}
```

### Bước 5 — Bootstrap state backend (chạy một lần)

```bash
RESOURCE_GROUP="rg-tfstate"
STORAGE_ACCOUNT="tfstate<project><env>"   # lowercase, max 24 chars, globally unique
CONTAINER="tfstate"
LOCATION="southeastasia"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT"
```

### Bước 6 — Triển khai toàn bộ environment

```bash
# Triển khai tất cả stacks theo đúng thứ tự dependency
cd infra/environments/dev
terragrunt run-all apply
```

Terragrunt tự động:
1. Phát hiện tất cả stacks
2. Xây dựng dependency graph
3. Deploy theo đúng thứ tự: management-groups → (connectivity ∥ management) → baseline → workloads
4. Bỏ qua các stacks có `skip = true` (identity, security mặc định)

### Bước 7 — Validate không cần Azure credentials (CI)

```bash
# Validate cú pháp toàn bộ landing zone — không cần subscription thực
cd infra/environments/dev
TERRAGRUNT_USE_LOCAL_BACKEND=true terragrunt run-all validate
```

---

## 4. Quản Lý Environment

### Thêm environment mới

Để thêm một environment mới (ví dụ: `uat`), chỉ cần **ba bước**:

```bash
# 1. Tạo thư mục environment mới
mkdir -p infra/environments/uat

# 2. Copy và chỉnh sửa env.hcl
cp infra/environments/dev/env.hcl infra/environments/uat/env.hcl
# Chỉnh sửa: environment, CIDR ranges, subscription IDs, feature flags

# 3. Copy terragrunt.hcl
cp infra/environments/dev/terragrunt.hcl infra/environments/uat/terragrunt.hcl
```

**Không cần thay đổi bất kỳ file nào trong `stacks/`.** Tất cả stacks đọc cấu hình từ `env.hcl` qua `find_in_parent_folders("env.hcl")`.

### Quy tắc CIDR — Không được overlap

| Environment | Hub VNet | Spoke VNet |
|-------------|----------|------------|
| dev | `10.0.0.0/16` | `10.1.0.0/16` |
| staging | `10.2.0.0/16` | `10.3.0.0/16` |
| uat | `10.4.0.0/16` | — |
| prod | `10.5.0.0/16` | `10.6.0.0/16` |

> Các CIDR **phải không overlap** để hub-spoke peering và on-premises connectivity hoạt động đúng.

### Lệnh thường dùng

```bash
# Triển khai toàn bộ environment
cd infra/environments/<env>
terragrunt run-all apply

# Xem plan trước khi apply
terragrunt run-all plan

# Destroy toàn bộ environment (theo thứ tự ngược)
terragrunt run-all destroy

# Validate syntax không cần credentials
TERRAGRUNT_USE_LOCAL_BACKEND=true terragrunt run-all validate

# Deploy chỉ một stack cụ thể
cd infra/stacks/platform/connectivity
terragrunt apply
```

---

## 5. Feature Flags

Tất cả feature flags được khai báo trong `infra/environments/{env}/env.hcl`. Thay đổi một flag và chạy lại `terragrunt run-all apply` — không cần sửa code.

### Platform Feature Flags

| Flag | Mặc định (dev) | Stack kiểm soát | Tài nguyên Azure |
|------|----------------|-----------------|------------------|
| `deploy_management_groups` | `true` | `stacks/management-groups/` | Azure Management Group hierarchy (Tenant Root, Platform, Application) |
| `deploy_connectivity` | `true` | `stacks/platform/connectivity/` | Hub VNet, Firewall, VPN Gateway, DNS Resolver, Bastion |
| `deploy_management` | `true` | `stacks/platform/management/` | Log Analytics Workspace, Defender for Cloud |
| `deploy_identity` | `false` | `stacks/platform/identity/` | Scaffold: Entra ID, Azure AD DS (chưa có resource thực tế) |
| `deploy_security` | `false` | `stacks/platform/security/` | Scaffold: Microsoft Sentinel, Security Center (chưa có resource thực tế) |

### Connectivity Sub-Flags

> Chỉ có hiệu lực khi `deploy_connectivity = true`.

| Flag | Mặc định (dev) | Tài nguyên Azure | Lưu ý |
|------|----------------|------------------|-------|
| `deploy_firewall` | `true` | `azurerm_firewall` + policy | Cần cho forced tunneling; giữ `true` trong production |
| `deploy_vpn_gateway` | `false` | `azurerm_virtual_network_gateway` | Tạo mất ~30–60 phút; chỉ bật khi cần on-premises connectivity |
| `deploy_dns_resolver` | `false` | `azurerm_private_dns_resolver` | Bật khi cần custom DNS forwarding |
| `deploy_bastion` | `false` | `azurerm_bastion_host` | Bật khi cần jump host; subnet `AzureBastionSubnet` phải có trong `hub_subnets` |

### Application Feature Flags

| Flag | Mặc định (dev) | Stack kiểm soát | Module Terraform |
|------|----------------|-----------------|------------------|
| `deploy_aks` | `true` | `stacks/application/workloads/aks/` | `modules/aks` |
| `deploy_postgresql` | `true` | `stacks/application/workloads/postgresql/` | `modules/postgresql-flexible` |
| `deploy_redis` | `false` | `stacks/application/workloads/redis/` | `modules/redis-cache` |
| `deploy_vm_bastion` | `false` | `stacks/application/workloads/vm-bastion/` | `modules/virtual-machine` + `modules/bastion` — VM Bastion workload trong spoke (R1) |
| `deploy_service_bus` | `false` | `stacks/application/workloads/service-bus/` | `modules/service-bus` — Service Bus Namespace workload (R2) |
| `deploy_apim` | `false` | — | **DEPRECATED** — dùng `deploy_service_bus` thay thế |

### Governance & Enterprise Hardening Flags (Sprint 3)

| Flag | Mặc định | Stack kiểm soát | Mô tả |
|------|----------|-----------------|-------|
| `deploy_rbac` | `false` | `stacks/governance/rbac/` | RBAC cross-subscription role assignments cho network và ops teams (Sprint 3) |
| `deploy_identity_ds` | `false` | `stacks/platform/identity/` | Azure AD Domain Services resource — chỉ có hiệu lực khi `deploy_identity = true` (Sprint 3) |
| `deploy_sentinel` | `false` | `stacks/platform/security/` | Microsoft Sentinel onboarding lên Log Analytics workspace — chỉ có hiệu lực khi `deploy_security = true` (Sprint 3) |
| `deploy_defender_plans` | `false` | `stacks/platform/security/` | Defender for Cloud pricing plans — chỉ có hiệu lực khi `deploy_security = true` (Sprint 3) |

### Ví dụ: Tắt VPN Gateway trong dev, bật trong prod

```hcl
# environments/dev/env.hcl
deploy_vpn_gateway = false

# environments/prod/env.hcl
deploy_vpn_gateway = true
```

Không cần thay đổi bất kỳ file nào trong `stacks/`.

### Lưu Ý: AKS VNet Integration

Kể từ Sprint 2, AKS stack tự động lấy `aks_subnet_id` từ output của baseline stack để tích hợp VNet:

- Baseline stack (`stacks/application/baseline/`) phải export output `aks_subnet_id` — đây là resource ID của subnet `aks` trong spoke VNet.
- Khi `subnet_id = null` (ví dụ: baseline bị skip hoặc mock), AKS nodes vẫn được tạo với default VNet của Azure — **backward compatible hoàn toàn**.
- Không cần thêm flag riêng — wiring được thực hiện tự động qua `dependency "baseline"` trong `aks/terragrunt.hcl`.

> **(Windows only)** Sau khi clone repo, junction points cần được tái tạo trước khi chạy bất kỳ lệnh Terragrunt nào:
> ```powershell
> # Mở PowerShell với quyền Administrator
> .\scripts\setup-junctions.ps1
> ```
> Xem [`scripts/setup-junctions.ps1`](scripts/setup-junctions.ps1) để biết chi tiết.

---

## 6. Thứ Tự Triển Khai

Terragrunt tự động xác định thứ tự deploy dựa trên `dependency {}` blocks. Không cần chỉ định thủ công.

```
Tier 0 — Tenant Scope (chạy một lần cho toàn tenant)
──────────────────────────────────────────────────────────
stacks/management-groups
   │ outputs: platform_mg_id, application_mg_id, tenant_root_mg_id
   ▼

Tier 1 — Platform (song song với nhau)
──────────────────────────────────────────────────────────
stacks/platform/connectivity          stacks/platform/management
   │ outputs:                            │ outputs:
   │  hub_vnet_id                        │  log_analytics_workspace_id
   │  firewall_private_ip                │  log_analytics_workspace_key
   │  hub_resource_group_name            │
   │  dns_server_ip                      │
   └──────────────┬───────────────────────┘
                  │
   (identity ∥ security — scaffold, skip=true mặc định)

Tier 2 — Application Baseline
──────────────────────────────────────────────────────────
                  ▼
         stacks/application/baseline
   ├─ phụ thuộc: connectivity → hub_vnet_id, firewall_private_ip
   ├─ phụ thuộc: management  → log_analytics_workspace_id
   │  outputs: spoke_vnet_id, key_vault_id, managed_identity_id
   ▼

Tier 3 — Application Workloads (song song với nhau)
──────────────────────────────────────────────────────────
workloads/aks    workloads/postgresql    workloads/vm-bastion    workloads/redis    workloads/service-bus
   ├─ phụ thuộc: baseline   → spoke_vnet_id, key_vault_id, managed_identity_id
   └─ phụ thuộc: management → log_analytics_workspace_id
```

**Khi một stack bị skip** (`skip = true`), Terragrunt bỏ qua stack đó và các downstream stacks sử dụng `mock_outputs` để tiếp tục validate/plan mà không cần credentials thực.

---

## 7. State File Layout

Mỗi stack có state file riêng biệt trong Azure Blob Storage container `tfstate`. State isolation đảm bảo `terraform destroy` trên một stack không ảnh hưởng stack khác.

```
Azure Blob Storage (container: tfstate)
├── stacks/management-groups/terraform.tfstate
├── stacks/platform/connectivity/terraform.tfstate
├── stacks/platform/management/terraform.tfstate
├── stacks/platform/identity/terraform.tfstate
├── stacks/platform/security/terraform.tfstate
├── dev/stacks/application/baseline/terraform.tfstate
├── dev/stacks/application/workloads/aks/terraform.tfstate
├── dev/stacks/application/workloads/postgresql/terraform.tfstate
├── dev/stacks/application/workloads/redis/terraform.tfstate
├── dev/stacks/application/workloads/service-bus/terraform.tfstate
├── dev/stacks/application/workloads/vm-bastion/terraform.tfstate
├── dev/stacks/governance/rbac/terraform.tfstate
├── staging/stacks/application/baseline/terraform.tfstate
├── staging/stacks/application/workloads/...
├── staging/stacks/governance/rbac/terraform.tfstate
├── prod/stacks/application/baseline/terraform.tfstate
├── prod/stacks/application/workloads/...
└── prod/stacks/governance/rbac/terraform.tfstate
```

> Platform stacks (management-groups, connectivity, management, identity, security) **không có environment prefix** vì chúng là tenant-level/subscription-level resources dùng chung.  
> Application stacks có environment prefix (`dev/`, `staging/`, `prod/`) vì mỗi environment deploy riêng biệt.

---

## 7a. RBAC Stack

### Mục Đích

Stack `stacks/governance/rbac/` quản lý **RBAC role assignments cross-subscription** cho các teams vận hành. Thay vì gán quyền thủ công qua Azure Portal, toàn bộ role assignments được version-controlled và deploy tự động qua `deploy_rbac = true`.

Ứng dụng điển hình:
- **Network team** cần `Network Contributor` trên connectivity subscription để quản lý hub VNet, firewall rules, và VPN.
- **Ops/SRE team** cần `Monitoring Contributor` trên management subscription để tạo alert rules và workbook.

### Cấu Trúc `rbac_assignments` Map

Khai báo trong `env.hcl`, map này nhận các entries tùy ý — mỗi entry là một role assignment độc lập:

```hcl
locals {
  deploy_rbac = true

  rbac_assignments = {
    # Key = tên định danh (dùng trong Terraform resource name)
    network_team_connectivity = {
      principal_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Object ID của group/SP/MI
      role_definition_name = "Network Contributor"
      scope                = "/subscriptions/${local.connectivity_subscription_id}"
    }
    ops_team_management = {
      principal_id         = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
      role_definition_name = "Monitoring Contributor"
      scope                = "/subscriptions/${local.management_subscription_id}"
    }
  }
}
```

| Field | Type | Mô tả |
|-------|------|-------|
| `principal_id` | `string` | Azure Object ID của user, group, service principal, hoặc managed identity nhận role |
| `role_definition_name` | `string` | Tên built-in hoặc custom role Azure (ví dụ: `"Network Contributor"`, `"Reader"`) |
| `scope` | `string` | Resource ID đầy đủ của scope gán quyền — subscription, resource group, hoặc resource cụ thể |

### Hai Role Assignments Mặc Định

Khi bật `deploy_rbac = true`, hai assignments sau được cấu hình sẵn trong template `env.hcl`:

| Key | Role | Subscription | Mục đích |
|-----|------|--------------|---------|
| `network_team_connectivity` | `Network Contributor` | `connectivity_subscription_id` | Network team quản lý hub VNet, Firewall, VPN, DNS |
| `ops_team_management` | `Monitoring Contributor` | `management_subscription_id` | Ops team tạo/sửa alert rules và Log Analytics workbooks |

> **CI/CD:** `principal_id = ""` (empty string) là hợp lệ khi `terragrunt run-all validate` — chỉ lỗi khi `apply` thực tế với Azure. Không cần điền Object ID thật trong CI pipelines.

---

## 8. Module Catalog

### Foundation

| Module | Mô tả | Tài nguyên chính |
|--------|-------|-----------------|
| [`resource-group`](modules/resource-group) | Azure Resource Group với mandatory tags | `azurerm_resource_group` |
| [`managed-identity`](modules/managed-identity) | User-assigned Managed Identity | `azurerm_user_assigned_identity` |
| [`rbac-assignment`](modules/rbac-assignment) | RBAC role assignments hàng loạt | `azurerm_role_assignment` |
| [`management-group`](modules/management-group) | Management Group hierarchy theo CAF | `azurerm_management_group` |

### Bảo Mật

| Module | Mô tả | Tài nguyên chính |
|--------|-------|-----------------|
| [`key-vault`](modules/key-vault) | Key Vault với RBAC mode | `azurerm_key_vault` |
| [`azure-policy`](modules/azure-policy) | ASB và CIS policy initiatives | `azurerm_subscription_policy_assignment` |
| [`defender-for-cloud`](modules/defender-for-cloud) | Defender plans theo resource type | `azurerm_security_center_subscription_pricing` |

### Networking

| Module | Mô tả | Tài nguyên chính |
|--------|-------|-----------------|
| [`vnet`](modules/vnet) | VNet + subnets với service endpoints | `azurerm_virtual_network`, `azurerm_subnet` |
| [`nsg`](modules/nsg) | NSG với configurable rules | `azurerm_network_security_group` |
| [`nat-gateway`](modules/nat-gateway) | NAT Gateway + Public IP | `azurerm_nat_gateway` |
| [`private-endpoint`](modules/private-endpoint) | Private endpoint + DNS zone | `azurerm_private_endpoint` |
| [`bastion`](modules/bastion) | Azure Bastion Host | `azurerm_bastion_host` |
| [`firewall`](modules/firewall) | Azure Firewall với Policy và Rule Collections | `azurerm_firewall` |
| [`vnet-peering`](modules/vnet-peering) | Hub-spoke VNet peering 2 chiều | `azurerm_virtual_network_peering` |
| [`vpn-gateway`](modules/vpn-gateway) | VPN Gateway | `azurerm_virtual_network_gateway` |
| [`dns-resolver`](modules/dns-resolver) | Azure DNS Private Resolver | `azurerm_private_dns_resolver` |
| [`route-table`](modules/route-table) | Route Table + subnet associations | `azurerm_route_table` |
| [`load-balancer`](modules/load-balancer) | Azure Load Balancer | `azurerm_lb` |

### Monitoring

| Module | Mô tả | Tài nguyên chính |
|--------|-------|-----------------|
| [`log-analytics`](modules/log-analytics) | Log Analytics Workspace | `azurerm_log_analytics_workspace` |
| [`app-insights`](modules/app-insights) | Application Insights | `azurerm_application_insights` |
| [`monitor-alerts`](modules/monitor-alerts) | Action Group + Metric Alerts | `azurerm_monitor_action_group` |
| [`diagnostic-settings`](modules/diagnostic-settings) | Diagnostic settings cho bất kỳ resource | `azurerm_monitor_diagnostic_setting` |

### Storage & Compute

| Module | Mô tả | Tài nguyên chính |
|--------|-------|-----------------|
| [`storage-account`](modules/storage-account) | Storage Account secure by default | `azurerm_storage_account` |
| [`container-registry`](modules/container-registry) | ACR (MI-based auth) | `azurerm_container_registry` |
| [`function-app`](modules/function-app) | Linux Function App | `azurerm_linux_function_app` |
| [`app-service`](modules/app-service) | Linux Web App | `azurerm_linux_web_app` |
| [`virtual-machine`](modules/virtual-machine) | Linux Virtual Machine | `azurerm_linux_virtual_machine` |
| [`aks`](modules/aks) | Azure Kubernetes Service | `azurerm_kubernetes_cluster` |

### Data & Messaging

| Module | Mô tả | Tài nguyên chính |
|--------|-------|-----------------|
| [`postgresql-flexible`](modules/postgresql-flexible) | PostgreSQL Flexible Server (private) | `azurerm_postgresql_flexible_server` |
| [`redis-cache`](modules/redis-cache) | Azure Cache for Redis | `azurerm_redis_cache` |
| [`cosmos-db`](modules/cosmos-db) | Cosmos DB Account (SQL API) | `azurerm_cosmosdb_account` |
| [`service-bus`](modules/service-bus) | Service Bus namespace | `azurerm_servicebus_namespace` |
| [`apim`](modules/apim) | API Management | `azurerm_api_management` |

---

## 9. Bảo Mật Mặc Định

| Quyết định | Lý do |
|-----------|-------|
| Key Vault RBAC mode | Access policies cũ bị deprecated; RBAC nhất quán với Azure AD |
| Managed Identity thay Service Principal | Không có secret cần quản lý; credentials tự rotate |
| `sensitive = true` cho passwords/keys | Ngăn in giá trị trong plan/apply logs |
| Storage: `allow_nested_items_to_be_public = false` | Không có public blob access ngoài ý muốn |
| PostgreSQL: không có public network | Chỉ kết nối qua private endpoint hoặc delegated subnet |
| `purge_soft_delete_on_destroy = false` | Tránh xóa vĩnh viễn Key Vault |
| Provider `azurerm ~> 4.0` | Pinned version — không tự động upgrade major |
| Không hardcode subscription ID | Tất cả IDs đọc từ `env.hcl` — không commit secret |

---

## 10. Tài Liệu

### Getting Started
- [`docs/onboarding-checklist.md`](docs/onboarding-checklist.md) — checklist triển khai lần đầu
- [`docs/naming-convention.md`](docs/naming-convention.md) — naming patterns cho 33+ resource types
- [`docs/landing-zone-guide.md`](docs/landing-zone-guide.md) — hướng dẫn kiến trúc hub-spoke

### Migration
- [`docs/migration-guide.md`](docs/migration-guide.md) — hướng dẫn migrate từ cấu trúc cũ sang CAF Landing Zone, bao gồm state rename commands và mapping cũ → mới

### Runbooks
- [`docs/runbooks/deploy.md`](docs/runbooks/deploy.md) — quy trình triển khai
- [`docs/runbooks/rollback.md`](docs/runbooks/rollback.md) — quy trình rollback
- [`docs/runbooks/state-management.md`](docs/runbooks/state-management.md) — quản lý Terraform state

### Reference
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — xử lý lỗi thường gặp
- [`CHANGELOG.md`](CHANGELOG.md) — lịch sử thay đổi phiên bản

---

## Versioning

| Loại thay đổi | Version bump | Ví dụ |
|--------------|-------------|-------|
| Đổi tên variable, xóa output (breaking) | **MAJOR** | `v1.x.x → v2.0.0` |
| Module mới, variable optional mới | **MINOR** | `v1.0.x → v1.1.0` |
| Bug fix, cập nhật documentation | **PATCH** | `v1.0.0 → v1.0.1` |

Xem [CHANGELOG.md](CHANGELOG.md) cho lịch sử đầy đủ.
