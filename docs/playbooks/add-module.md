# Playbook: Adding a New Module to the Library

---

## Checklist nhanh

```
□ 1. Kiểm tra module chưa có trong catalog
□ 2. Tạo modules/<tên-module>/
□ 3. Viết variables.tf — 5 biến bắt buộc + inputs riêng
□ 4. Viết main.tf — naming, tags, security defaults
□ 5. Viết outputs.tf — descriptions, sensitive = true
□ 6. terraform validate
□ 7. Wire vào environments/{env}/
□ 8. Cập nhật docs
```

---

## Bước 1 — Kiểm tra module đã có chưa

```bash
ls infra/modules/
```

Xem thêm [README.md Module Catalog](../../README.md#module-catalog). Nếu chưa có → tiếp tục.

---

## Bước 2 — Tạo folder

```bash
mkdir infra/modules/<tên-module>
```

Tên: lowercase, dashes. Ví dụ: `event-hub`, `front-door`, `container-apps`.

---

## Bước 3 — `variables.tf`

5 biến bắt buộc trên **mọi** module:

```hcl
variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'acme'). Combined with environment to produce resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy resources into."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags merged into all resources."
  type        = map(string)
  default     = {}
}
```

Thêm variables đặc thù, mỗi cái phải có `description`.

---

## Bước 4 — `main.tf`

### Provider block

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

### Naming pattern

```hcl
resource "azurerm_<type>" "this" {
  name                = "${var.name_prefix}-${var.environment}-<suffix>"
  resource_group_name = var.resource_group_name
  location            = var.location
  ...
}
```

Xem [`docs/naming-convention.md`](../naming-convention.md) để chọn suffix.

### Tag merge — bắt buộc

```hcl
tags = merge(
  {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  },
  var.tags
)
```

### Feature flag cho optional sub-resources

```hcl
variable "create_private_endpoint" {
  description = "Whether to create a private endpoint for this resource."
  type        = bool
  default     = false
}

resource "azurerm_private_endpoint" "this" {
  count = var.create_private_endpoint ? 1 : 0
  ...
}
```

### `for_each` thay `count` cho resources có identifier

```hcl
# ✅ Đúng
resource "azurerm_eventhub" "this" {
  for_each = var.event_hubs
  name     = each.key
  ...
}

# ❌ Sai — gây state drift khi xóa phần tử giữa list
resource "azurerm_eventhub" "this" {
  count = length(var.event_hubs)
  ...
}
```

### Security defaults — hardcode, không để configurable

```hcl
# Storage
https_traffic_only_enabled      = true
min_tls_version                 = "TLS1_2"
allow_nested_items_to_be_public = false

# PostgreSQL
public_network_access_enabled = false

# Redis
minimum_tls_version  = "1.2"
non_ssl_port_enabled = false
```

---

## Bước 5 — `outputs.tf`

Mọi output phải có `description`. Sensitive phải có `sensitive = true`:

```hcl
output "resource_id" {
  description = "Resource ID of the <resource>."
  value       = azurerm_<resource>.this.id
}

output "connection_string" {
  description = "Primary connection string."
  value       = azurerm_<resource>.this.primary_connection_string
  sensitive   = true
}
```

---

## Bước 6 — Validate

```bash
cd infra/modules/<tên-module>
terraform init
terraform validate
# Expected: Success! The configuration is valid.
```

---

## Bước 7 — Wire vào environments

Với Terragrunt, module được gọi từ `infra/environments/{env}/` (hoặc `platform/`).

### Thêm vào compute.tf / database.tf / networking.tf của env

```hcl
# infra/environments/dev/compute.tf (ví dụ)
module "event_hub" {
  count     = var.deploy_event_hub ? 1 : 0
  source    = "../../modules/event-hub"
  providers = { azurerm = azurerm.workload }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags

  # module-specific inputs
  event_hubs = var.event_hubs
}
```

### Thêm feature flag vào variables.tf của env

```hcl
variable "deploy_event_hub" {
  description = "Whether to deploy Event Hub Namespace."
  type        = bool
  default     = false
}
```

### Wire vào terragrunt.hcl nếu cần inject từ platform

```hcl
# environments/dev/terragrunt.hcl
inputs = {
  ...
  deploy_event_hub = true   # hoặc giữ false, bật từng env
}
```

### Validate

```bash
cd infra/environments/dev
terragrunt validate
```

---

## Bước 8 — Cập nhật docs

- [ ] `docs/naming-convention.md` — thêm suffix mới vào Summary Table
- [ ] `README.md` — thêm row vào Module Catalog đúng nhóm
- [ ] `CHANGELOG.md` — thêm entry vào `[Unreleased]`

---

## Checklist hoàn thành

```
□ modules/<tên>/: main.tf + variables.tf + outputs.tf
□ 5 biến bắt buộc có description
□ Naming pattern đúng
□ Tag merge có Project + Environment + ManagedBy
□ Security defaults hardcoded
□ sensitive = true cho secrets/keys/connection strings
□ for_each (không phải count) cho resources có identifier
□ terraform validate pass
□ Wired vào environments/dev/ với provider alias đúng
□ terragrunt validate pass
□ naming-convention.md cập nhật
□ README.md cập nhật
□ CHANGELOG.md cập nhật
```
