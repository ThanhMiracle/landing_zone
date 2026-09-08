# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — ALZ Hardening and Completion

### Added

#### Sprint 1 — Usability Fixes
- `deploy_vm_bastion` flag trong `env.hcl` (tất cả 6 environments) — kiểm soát VM Bastion workload stack
- `deploy_service_bus` flag trong `env.hcl` — kiểm soát Service Bus workload stack
- Script `infra/scripts/setup-junctions.ps1` — tái tạo Windows junction points sau khi clone

#### Sprint 2 — CAF Completeness
- `subnet_id` variable trong `modules/aks/variables.tf` — Resource ID của subnet dành cho system node pool; khi set, AKS nodes được deploy vào subnet này (VNet integration); backward-compatible khi `null`
- `aks_subnet_id` output trong `stacks/application/baseline/outputs.tf` — Resource ID của subnet `aks` trong spoke VNet; consumed by AKS workload stack để tích hợp VNet (R6)
- `management_group_id` variable và `scope_type = "management_group"` support trong `modules/azure-policy/` — cho phép gán policy initiatives ở Management Group scope
- Policy assignments ở MG scope trong `stacks/management-groups/main.tf`: ASB cho Platform MG, ASB + CIS cho Application MG (3 module calls mới)
- Diagnostic Settings cho 4 workloads: AKS (`kube-apiserver`, `kube-audit`, v.v.), PostgreSQL (`PostgreSQLLogs`), Redis (`ConnectedClientList`), Service Bus (`OperationalLogs`, `RuntimeAuditLogs`) — gửi logs về Log Analytics workspace trung tâm; conditional khi `log_analytics_workspace_id` được set

#### Sprint 3 — Enterprise Hardening
- Stack mới `stacks/governance/rbac/` với `rbac_assignments` map support — RBAC cross-subscription assignments; kiểm soát bởi `deploy_rbac` flag
- `deploy_identity_ds` flag + resource `azurerm_active_directory_domain_service` (conditional) trong `stacks/platform/identity/` — bật Azure AD Domain Services; yêu cầu Azure AD Premium P1/P2; có `lifecycle { prevent_destroy = true }`
- `deploy_sentinel` flag + `azurerm_sentinel_log_analytics_workspace_onboarding` resource (conditional) trong `stacks/platform/security/` — onboard Microsoft Sentinel lên Log Analytics workspace
- `deploy_defender_plans` flag + Defender for Cloud pricing plans (conditional) trong `stacks/platform/security/` — bật Defender for Cloud plans
- Tất cả 6 `env.hcl` cập nhật với Governance Feature Flags Sprint 3: `deploy_rbac`, `rbac_assignments`, `deploy_identity_ds`, `deploy_sentinel`, `deploy_defender_plans`

### Changed

#### Sprint 1 — Usability Fixes
- `vm-bastion/terragrunt.hcl`: skip condition đổi từ `deploy_bastion` sang `deploy_vm_bastion`
- `service-bus/terragrunt.hcl`: skip condition đổi từ `deploy_apim` sang `deploy_service_bus`

#### Sprint 2 — CAF Completeness
- `stacks/management-groups/main.tf`: thêm 3 MG-scope policy module calls (ASB cho Platform MG, ASB + CIS cho Application MG)
- `stacks/application/workloads/aks/main.tf`: `subnet_id` được wire từ `dependency.baseline.outputs.aks_subnet_id` qua `var.aks_subnet_id`

#### Sprint 3 — Enterprise Hardening
- `stacks/platform/identity/main.tf`: mở rộng từ scaffold sang conditional AD DS resource (`azurerm_active_directory_domain_service`)
- `stacks/platform/identity/terragrunt.hcl`: thêm `deploy_identity_ds` input từ `env.hcl`
- `stacks/platform/security/main.tf`: mở rộng từ scaffold sang Sentinel onboarding + Defender for Cloud plans (conditional resources)
- `stacks/platform/security/terragrunt.hcl`: thêm `dependency "management"` (để lấy `log_analytics_workspace_id`) + 3 inputs mới: `deploy_sentinel`, `deploy_defender_plans`, `log_analytics_workspace_id`

### Deprecated
- `deploy_apim`: được thay thế bởi `deploy_service_bus`. Sẽ xóa ở release tiếp theo.
  **Migration:** nếu đang có `deploy_apim = true`, đổi sang `deploy_service_bus = true`.

### Removed

### Fixed
- Flag naming: `deploy_bastion` không còn bị dùng nhầm cho VM Bastion workload
- Flag naming: `deploy_apim` không còn bị dùng cho Service Bus workload

### Security

---

## [2.0.0] - 2025-07-31

> **Refactor:** Migrate `infra/` to Azure CAF Landing Zone architecture  
> **⚠️ Breaking Changes — Xem mục [Breaking Changes] bên dưới trước khi upgrade.**

### ⚠️ Breaking Changes

- **Đường dẫn stacks thay đổi hoàn toàn:**
  - `infra/platform/connectivity/` → `infra/stacks/platform/connectivity/`
  - `infra/platform/management/` → `infra/stacks/platform/management/`
  - `infra/environments/{env}/*.tf` (workload resources) → `infra/stacks/application/baseline/`
  - Tất cả Terragrunt `config_path` trong dependency blocks phải cập nhật theo đường dẫn mới.

- **State keys thay đổi** — Nếu có resources đang chạy trên Azure, cần chạy `terraform state mv` hoặc `terraform import` trước khi apply kiến trúc mới:

  | Stack | State Key cũ | State Key mới |
  |---|---|---|
  | connectivity | `platform/connectivity/terraform.tfstate` | `stacks/platform/connectivity/terraform.tfstate` |
  | management | `platform/management/terraform.tfstate` | `stacks/platform/management/terraform.tfstate` |
  | baseline (dev) | `environments/dev/terraform.tfstate` | `dev/stacks/application/baseline/terraform.tfstate` |
  | baseline (staging) | `environments/staging/terraform.tfstate` | `staging/stacks/application/baseline/terraform.tfstate` |
  | baseline (prod) | `environments/prod/terraform.tfstate` | `prod/stacks/application/baseline/terraform.tfstate` |

  > Lệnh import state mẫu:
  > ```bash
  > # Backup state cũ trước
  > terraform state pull > backup-$(date +%Y%m%d).tfstate
  >
  > # Rename state key trong Azure Blob Storage
  > az storage blob copy start \
  >   --source-container tfstate \
  >   --source-blob "platform/connectivity/terraform.tfstate" \
  >   --destination-container tfstate \
  >   --destination-blob "stacks/platform/connectivity/terraform.tfstate" \
  >   --account-name <YOUR_STORAGE_ACCOUNT>
  > ```

- **`infra/environments/{env}/` không còn chứa `.tf` files** — Mọi Terraform resource definitions đã chuyển sang `infra/stacks/`. Các `backend.tf`, `provider_generated.tf`, `*.tf` cũ trong thư mục environment sẽ bị xóa và không còn được sử dụng.

- **Subscription IDs không còn hardcode trong root `terragrunt.hcl`** — Tất cả subscription IDs phải được khai báo trong `env.hcl` của từng environment. Cần cập nhật `env.hcl` trước khi chạy `apply`.

- **Provider block thay đổi** — Mỗi stack tự generate provider block riêng với `subscription_id` và `alias` phù hợp. Root `terragrunt.hcl` chỉ chứa version constraints, không còn có `subscription_id`.

### Added

- **Module `management-group`** (`infra/modules/management-group/`): Module Terraform mới để tạo và quản lý Azure Management Group hierarchy theo mô hình CAF. Hỗ trợ `parent_management_group_id`, `subscriptions` association, và output `management_group_id`.

- **Stack `management-groups`** (`infra/stacks/management-groups/`): Terragrunt stack Tier 0 để deploy toàn bộ Management Group hierarchy một lần cho toàn tenant. Tạo 3 management groups: `{prefix}-root`, `{prefix}-platform`, `{prefix}-application`.

- **Stack `platform/identity` (scaffold)** (`infra/stacks/platform/identity/`): Scaffold cho Identity subscription — hiện chỉ deploy placeholder resource group `{prefix}-{env}-identity-rg`. Tắt mặc định (`deploy_identity = false`). Được chuẩn bị sẵn cho Entra ID và Azure AD Domain Services.

- **Stack `platform/security` (scaffold)** (`infra/stacks/platform/security/`): Scaffold cho Security subscription — hiện chỉ deploy placeholder resource group `{prefix}-{env}-security-rg`. Tắt mặc định (`deploy_security = false`). Được chuẩn bị sẵn cho Microsoft Sentinel và Defender for Cloud SIEM.

- **Workload template: AKS** (`infra/stacks/application/workloads/aks/`): Generic Terragrunt template để deploy AKS cluster. Nhận `spoke_vnet_id`, `key_vault_id`, `log_analytics_workspace_id` từ upstream stacks qua dependency blocks. Enable bằng `deploy_aks = true` trong `env.hcl`.

- **Workload template: PostgreSQL** (`infra/stacks/application/workloads/postgresql/`): Generic Terragrunt template để deploy PostgreSQL Flexible Server với subnet delegation. Enable bằng `deploy_postgresql = true`.

- **Workload template: VM-Bastion** (`infra/stacks/application/workloads/vm-bastion/`): Generic Terragrunt template kết hợp Linux VM và Azure Bastion. Dùng `AzureBastionSubnet` từ `app_subnets`. Enable bằng `deploy_bastion = true`.

- **Workload template: Redis** (`infra/stacks/application/workloads/redis/`): Generic Terragrunt template để deploy Azure Cache for Redis. Enable bằng `deploy_redis = true`.

- **Workload template: Service Bus** (`infra/stacks/application/workloads/service-bus/`): Generic Terragrunt template để deploy Service Bus Namespace. Enable bằng `deploy_apim = true` (theo convention R9.9).

- **File `env.hcl` per environment**: Nguồn sự thật duy nhất cho mỗi environment. Thêm environment mới chỉ cần tạo thư mục và copy-modify `env.hcl` — không cần thay đổi `stacks/`.

- **Feature flags** trong `env.hcl`: `deploy_management_groups`, `deploy_connectivity`, `deploy_management`, `deploy_identity`, `deploy_security`, `deploy_firewall`, `deploy_vpn_gateway`, `deploy_dns_resolver`, `deploy_bastion`, `deploy_aks`, `deploy_postgresql`, `deploy_redis`, `deploy_apim`. Mỗi flag có thể bật/tắt component tương ứng mà không thay đổi code.

- **State isolation per stack**: Mỗi stack trong `infra/stacks/` có state file riêng trong Azure Blob Storage container `tfstate`. Platform stacks không có environment prefix; application stacks có `{environment}/` prefix.

- **Multi-subscription provider pattern**: Mỗi stack tự generate `azurerm` provider với `subscription_id` đúng từ `env.hcl`. Hỗ trợ single-subscription (tất cả IDs giống nhau) và multi-subscription deployment theo đúng mô hình CAF.

- **Local backend override cho CI**: `TERRAGRUNT_USE_LOCAL_BACKEND=true` cho phép chạy `terragrunt run-all validate` mà không cần Azure credentials hay backend thực tế.

- **Mock outputs cho dependency blocks**: Tất cả dependency blocks có `mock_outputs` và `mock_outputs_allowed_terraform_commands = ["validate", "plan"]` để CI validate pass ngay cả khi upstream stacks bị skip.

### Changed

- **Root `terragrunt.hcl`** cập nhật: xóa hardcoded subscription IDs, thêm `TERRAGRUNT_USE_LOCAL_BACKEND` override, `remote_state.config.key` dùng `path_relative_to_include()`. Provider block chỉ còn version constraints.

- **Stack `platform/connectivity`** migrate từ `infra/platform/connectivity/` sang `infra/stacks/platform/connectivity/`. Tích hợp `env.hcl` qua `read_terragrunt_config(find_in_parent_folders("env.hcl"))`. Provider alias `azurerm.connectivity` với `connectivity_subscription_id`.

- **Stack `platform/management`** migrate từ `infra/platform/management/` sang `infra/stacks/platform/management/`. Provider alias `azurerm.management` với `management_subscription_id`.

- **Application baseline** refactor từ environment-specific sang generic stack tại `infra/stacks/application/baseline/`. Nhận hub outputs từ connectivity dependency và workspace ID từ management dependency.

- **Thứ tự deploy** được quản lý tự động bởi Terragrunt dependency graph: Management Groups → (Connectivity ∥ Management) → Baseline → Workloads (parallel). Chạy bằng một lệnh duy nhất `terragrunt run-all apply` từ `infra/environments/{env}/`.

- **Naming convention** thống nhất: `{name_prefix}-{environment}-{suffix}`. Mandatory tags: `{ Project, Environment, ManagedBy = "terraform" }` trên toàn bộ resources.

- **CIDR scheme** environments: dev `10.0-1.x/16`, staging `10.2-3.x/16`, prod `10.5-6.x/16`.

### Removed

- **`infra/platform/` folder** đã xóa hoàn toàn. Nội dung đã migrate sang `infra/stacks/platform/connectivity/` và `infra/stacks/platform/management/`.

- **`.tf` files trong `infra/environments/{env}/`** đã xóa. Các files bị xóa bao gồm: `main.tf`, `networking.tf`, `compute.tf`, `database.tf`, `backend.tf`, `provider_generated.tf`, `*.lock.hcl` trong thư mục `environments/dev/`, `environments/staging/`, `environments/prod/`. Chỉ giữ lại `env.hcl` và `terragrunt.hcl`.

## [1.0.0] - 2026-07-31

### Added
- Module `resource-group`: Azure Resource Group with mandatory tagging
- Module `managed-identity`: User-Assigned Managed Identity
- Module `rbac-assignment`: Role Assignment via for_each map
- Module `key-vault`: Key Vault with RBAC mode, keys and secrets
- Module `azure-policy`: Azure Security Benchmark and CIS initiative assignments
- Module `defender-for-cloud`: Microsoft Defender subscription pricing
- Module `vnet`: Virtual Network with configurable subnets
- Module `nsg`: Network Security Group with rules
- Module `nat-gateway`: NAT Gateway for private subnet outbound
- Module `private-endpoint`: Private Endpoint with optional DNS zone
- Module `bastion`: Azure Bastion Host
- Module `log-analytics`: Log Analytics Workspace
- Module `app-insights`: Application Insights (workspace-based)
- Module `monitor-alerts`: Action Group and Metric Alerts
- Module `diagnostic-settings`: Diagnostic Settings for any resource
- Module `storage-account`: Storage Account with security defaults
- Module `container-registry`: Azure Container Registry
- Module `function-app`: Linux Function App with Service Plan
- Module `app-service`: Linux Web App with Service Plan
- Module `postgresql-flexible`: PostgreSQL Flexible Server
- Module `service-bus`: Service Bus Namespace, Queues, Topics
- Module `apim`: API Management
- Module `aks`: Azure Kubernetes Service
- Module `cosmos-db`: Cosmos DB Account (SQL API)
- Module `redis-cache`: Azure Cache for Redis
- Module `load-balancer`: Azure Load Balancer (public and internal)
- Module `virtual-machine`: Linux Virtual Machine
- Module `firewall`: Azure Firewall with Policy and Rule Collections
- Module `vnet-peering`: Bidirectional VNet Peering (hub-spoke)
- Module `vpn-gateway`: VPN Gateway with Local Network Gateways
- Module `dns-resolver`: Azure DNS Private Resolver
- Module `route-table`: Route Table with subnet associations
- Environments: `dev`, `test`, `uat`, `pre-production`, `prod` baselines
- Platform stacks: `connectivity` (hub network), `management` (log analytics, defender)
- Workload stacks: `dev`, `test`, `uat`, `pre-production`, `prod` (Terragrunt CAF pattern)
- Documentation: naming-convention.md, onboarding-checklist.md, terragrunt-caf-guide.md

[Unreleased]: https://github.com/your-org/your-repo/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/your-org/your-repo/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/your-org/your-repo/releases/tag/v1.0.0
