# Runbook: Terraform State Management

Hướng dẫn vận hành Terraform state — đọc, sửa, di chuyển, và xử lý sự cố liên quan đến state.

---

## Nguyên tắc cơ bản

- **Không edit state file trực tiếp** — luôn dùng `terraform state` commands
- **Backup trước khi thay đổi** — Azure Blob versioning giữ history, nhưng vẫn nên pull về local trước
- **State lock** — Azure Blob dùng blob lease để lock. Nếu apply bị interrupt, lock có thể bị stuck

---

## Xem state hiện tại

```bash
# Liệt kê tất cả resources trong state
terraform state list

# Xem chi tiết một resource
terraform state show module.key_vault.azurerm_key_vault.this

# Pull state về dạng JSON để inspect
terraform state pull | jq .
```

---

## Di chuyển resource trong state (rename)

Khi refactor — ví dụ đổi tên module từ `module.kv` sang `module.key_vault`:

```bash
terraform state mv \
  module.kv.azurerm_key_vault.this \
  module.key_vault.azurerm_key_vault.this
```

> Sau khi `state mv`, chạy `terraform plan` để confirm "No changes".

---

## Xóa resource khỏi state (không xóa Azure resource)

Dùng khi resource cần được quản lý ngoài Terraform, hoặc khi cần reimport:

```bash
terraform state rm module.resource_group.azurerm_resource_group.this
```

Resource vẫn tồn tại trên Azure, chỉ bị xóa khỏi Terraform tracking.

---

## Import resource vào state

Khi resource đã tồn tại trên Azure nhưng chưa có trong state:

```bash
# Format: terraform import <terraform-address> <azure-resource-id>

# Resource Group
terraform import \
  module.resource_group.azurerm_resource_group.this \
  "/subscriptions/<sub>/resourceGroups/<rg-name>"

# VNet
terraform import \
  module.vnet.azurerm_virtual_network.this \
  "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"

# Key Vault
terraform import \
  module.key_vault.azurerm_key_vault.this \
  "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv-name>"

# Storage Account
terraform import \
  module.storage_account.azurerm_storage_account.this \
  "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<account-name>"

# Log Analytics Workspace
terraform import \
  module.log_analytics.azurerm_log_analytics_workspace.this \
  "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<ws-name>"
```

Sau khi import, verify:

```bash
terraform plan -var-file=terraform.tfvars
# Expected: No changes (nếu config match với actual resource)
# Nếu có changes: review và điều chỉnh variables cho match
```

---

## Xử lý state lock bị stuck

State lock bị stuck khi `terraform apply` bị kill đột ngột.

```bash
# Xem thông tin lock
terraform force-unlock <LOCK_ID>
```

`LOCK_ID` xuất hiện trong error message khi bị lock. Ví dụ:
```
Error: Error locking state: Error acquiring the state lock:
  Lock Info:
    ID: 12345678-...
```

> ⚠️ Chỉ `force-unlock` khi **chắc chắn không có ai đang apply**. Force unlock khi có concurrent apply gây state corruption.

Cách lấy lock ID từ Azure nếu error message không rõ:

```bash
az storage blob show \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --name "environments/<env>/terraform.tfstate" \
  --query "properties.lease"
```

---

## Backup state thủ công

```bash
# Pull state về local
terraform state pull > backups/tfstate-$(date +%Y%m%d-%H%M%S).json

# Hoặc download từ Azure Blob trực tiếp
az storage blob download \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --name "environments/<env>/terraform.tfstate" \
  --file "backups/tfstate-$(date +%Y%m%d).json"
```

---

## Restore state từ backup

```bash
# Xem các versions có sẵn (Azure Blob versioning)
az storage blob list \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --prefix "environments/<env>/terraform.tfstate" \
  --include v \
  --query "[].{versionId:versionId, lastModified:properties.lastModified}" \
  -o table

# Download version cụ thể
az storage blob download \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --name "environments/<env>/terraform.tfstate" \
  --version-id "<version-id>" \
  --file terraform.tfstate.restore

# Inspect trước
cat terraform.tfstate.restore | jq '.resources | length'

# Upload lại thành version mới (ghi đè current)
terraform state push terraform.tfstate.restore
```

---

## Di chuyển state giữa backends (migrate)

Khi cần đổi storage account hoặc container:

```bash
# Bước 1: Backup state hiện tại
terraform state pull > state-before-migrate.json

# Bước 2: Cập nhật backend.tfvars với destination mới

# Bước 3: Init với migrate-state flag
terraform init -backend-config=backend.tfvars -migrate-state

# Bước 4: Confirm migration

# Bước 5: Verify
terraform state list  # phải giống hệt trước migrate
terraform plan        # Expected: No changes
```

---

## Layout state files trên Azure Blob

```
Storage Account: tfstate<project>
Container: tfstate
├── environments/dev/terraform.tfstate
├── environments/test/terraform.tfstate
├── environments/uat/terraform.tfstate
├── environments/pre-production/terraform.tfstate
├── environments/prod/terraform.tfstate
│
│ (Pattern B — Terragrunt)
├── platform/connectivity/terraform.tfstate
├── platform/management/terraform.tfstate
├── environments/dev/terraform.tfstate
├── environments/test/terraform.tfstate
├── environments/uat/terraform.tfstate
├── environments/pre-production/terraform.tfstate
└── environments/prod/terraform.tfstate
```

Mỗi file là **independent state** — không có cross-reference giữa các files, trừ khi dùng `terraform_remote_state` data source (Pattern B dùng Terragrunt dependency blocks thay thế).

---

## Lệnh hay dùng — quick reference

```bash
# List resources
terraform state list

# Show resource detail
terraform state show <address>

# Move resource
terraform state mv <old-address> <new-address>

# Remove from state (keep in Azure)
terraform state rm <address>

# Import from Azure
terraform import <address> <azure-id>

# Pull state to stdout
terraform state pull

# Push local state (override remote)
terraform state push <file>

# Force unlock
terraform force-unlock <lock-id>
```
