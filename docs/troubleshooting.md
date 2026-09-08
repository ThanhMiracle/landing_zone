# Troubleshooting Guide

Danh sách lỗi phổ biến khi làm việc với repo này và cách fix.

---

## Authentication & Access

### `Error: No valid credential sources found`

```
Error: No valid credential sources found for AWS Provider.
```
*(hoặc Azure equivalent)*

**Nguyên nhân:** Chưa login Azure CLI hoặc token hết hạn.

**Fix:**
```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az account show  # verify đúng subscription
```

---

### `Error: authorization failed` hoặc `Insufficient privileges`

**Nguyên nhân:** Account thiếu quyền. Cần ít nhất `Contributor` + `User Access Administrator`.

**Fix:**
```bash
# Kiểm tra role hiện tại
az role assignment list --assignee "<your-email>" --output table

# Yêu cầu admin grant thêm quyền
az role assignment create \
  --assignee "<your-email>" \
  --role "Contributor" \
  --scope "/subscriptions/<sub-id>"
```

---

## Terraform Init

### `Error: Failed to query available provider packages`

**Nguyên nhân:** Không có internet hoặc registry.terraform.io bị block.

**Fix:**
```bash
# Dùng mirror nếu có
terraform init -plugin-dir="<path-to-local-mirror>"

# Hoặc set proxy
export HTTPS_PROXY="http://proxy.company.com:8080"
terraform init
```

---

### `Error: Backend initialization required`

**Nguyên nhân:** Chưa chạy `terraform init` hoặc backend config thay đổi.

**Fix:**
```bash
terraform init -backend-config=backend.tfvars -reconfigure
```

---

### `.terraform.lock.hcl` version conflict

```
Error: Incompatible provider version
```

**Fix:**
```bash
# Xóa lock file và reinit
rm .terraform.lock.hcl
terraform init -backend-config=backend.tfvars
# Commit lock file mới
git add .terraform.lock.hcl
```

---

## Terraform Plan / Validate

### `Error: Unsupported argument` — attribute không tồn tại

```
Error: Unsupported argument
An argument named "xxx" is not expected here.
```

**Nguyên nhân:** Tên attribute sai hoặc attribute đã bị deprecated trong provider version mới.

**Fix:**
1. Kiểm tra [azurerm provider changelog](https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md) cho version đang dùng
2. Tìm attribute đúng trong [Terraform Registry docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

### `Error: Missing required argument`

**Nguyên nhân:** Module có required variable chưa được set.

**Fix:** Thêm variable vào `terraform.tfvars` hoặc module call trong `.tf` file.

---

### Resource bị **replace** không mong muốn trong plan

```
# module.xxx will be replaced
-/+ resource "azurerm_xxx" "this" {
```

**Nguyên nhân phổ biến:**
- Thay đổi `name_prefix` hoặc `environment` (tên resource thay đổi → recreate)
- Thay đổi immutable attribute (ví dụ: storage account replication type)
- Module refactor thay đổi Terraform address

**Fix:**
```bash
# Nếu resource đã tồn tại và không cần recreate → dùng state mv
terraform state mv <old-address> <new-address>

# Sau đó plan lại — expected: No changes
```

---

## Naming Constraints

### Key Vault name > 24 characters

```
Error: "name" may only contain alphanumeric characters and dashes, must begin with a letter,
end with a letter or digit, and not contain consecutive dashes. Max length: 24.
```

**Nguyên nhân:** `name_prefix` + `environment` quá dài. Pattern là `{prefix}-{env}-kv`.

**Ví dụ tính toán:**
- `myproject-pre-production-kv` = 28 chars → quá dài
- Fix: rút ngắn `name_prefix` xuống ≤ 8 chars, hoặc rút `environment` = `preprod`

```hcl
# terraform.tfvars
name_prefix = "mypj"       # thay vì "myproject"
environment = "preprod"   # thay vì "pre-production"
```

---

### Storage Account name conflict

```
Error: The storage account named "xxx" is already taken.
```

**Nguyên nhân:** Storage account names globally unique trên toàn Azure.

**Fix:** Thêm suffix ngắn vào `name_prefix`:

```hcl
name_prefix = "acme01"  # thay vì "acme"
```

Storage account sẽ là `acme01devst` thay vì `acmedevst`.

---

### ACR name conflict

Tương tự storage account — ACR login server globally unique.

```hcl
name_prefix = "acme01"
# → ACR name: acme01devacr
```

---

## State Issues

### `Error: Error acquiring the state lock`

```
Error: Error locking state: Error acquiring the state lock
Lock Info: ID: xxxx-xxxx-xxxx
```

**Nguyên nhân:** Previous apply bị interrupt, lock chưa được release.

**Fix:**
```bash
terraform force-unlock <LOCK_ID>
# Chỉ chạy khi chắc chắn không có concurrent apply
```

---

### `terraform plan` hiện thị changes dù không sửa gì

**Nguyên nhân phổ biến:**
1. Provider version thay đổi (drift giữa lock file và registry)
2. Azure API trả về value khác với config (ví dụ: case sensitivity, whitespace)
3. Default value của Azure khác với Terraform default

**Cách điều tra:**
```bash
terraform plan -var-file=terraform.tfvars 2>&1 | grep "forces replacement\|must be replaced"
```

Nếu chỉ là `~ update in-place` (không phải `+/- replace`) và không có security impact → thường safe to apply.

---

## Key Vault

### `Error: The caller does not have permission to perform the action`

**Nguyên nhân:** Key Vault dùng RBAC mode. Account cần role `Key Vault Administrator` hoặc `Key Vault Secrets Officer` để tạo secrets.

**Fix:**
```bash
az role assignment create \
  --assignee "<your-object-id>" \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv-name>"
```

---

### Key Vault bị purge protected — destroy fails

```
Error: deleting Key Vault: the Key Vault still has Purge Protection enabled
```

**Nguyên nhân:** `purge_protection_enabled = true` — Key Vault không thể xóa hẳn ngay.

**Fix:** Key Vault sẽ vào trạng thái "soft deleted" trong 90 ngày. Để recover:
```bash
az keyvault recover --name "<kv-name>"
```

Để xóa hẳn (không khuyến nghị):
```bash
az keyvault purge --name "<kv-name>" --no-wait
# Cần chờ 90 ngày nếu purge protection enabled
```

---

## PostgreSQL

### `delegated_subnet_id` không có delegation

```
Error: creating Flexible Server: the subnet must be delegated to Microsoft.DBforPostgreSQL/flexibleServers
```

**Fix:** Thêm delegation vào subnet trong VNet config:

```hcl
subnets = {
  postgresql = {
    address_prefixes = ["10.0.2.0/24"]
    delegation = {
      name = "postgresql"
      service_delegation = {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}
```

---

### `private_dns_zone_id` không match

```
Error: The resource with the id "/subscriptions/.../privateDnsZones/xxx" was not found
```

**Fix:** Tạo private DNS zone trước hoặc dùng `private-endpoint` module với `create_dns_zone = true`.

---

## Terragrunt

### `Error: Could not find a terragrunt.hcl file`

```
ERRO[0000] Could not find a terragrunt.hcl in any of the parent folders
```

**Nguyên nhân:** Không có `terragrunt.hcl` trong directory hoặc parent folders.

**Fix:** Luôn chạy Terragrunt từ đúng directory có `terragrunt.hcl`:
```bash
cd infra/environments/dev  # có terragrunt.hcl
terragrunt plan
```

---

### Dependency output vẫn là mock sau khi platform đã apply

**Nguyên nhân:** Chạy plan trước khi platform stacks được apply, hoặc state key path sai.

**Fix:**
```bash
# Verify platform đã apply
cd infra/platform/connectivity
terragrunt output  # phải có real values

# Verify key path trong state
az storage blob list \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --query "[].name" -o tsv
```

---

## Azure Policy

### `Error: creating Policy Assignment: the subscription is not registered`

**Nguyên nhân:** Module `defender-for-cloud` cần subscription-level permission.

**Fix:** Xem `modules/defender-for-cloud/README.md` — cần `Security Admin` role hoặc `Owner` ở subscription scope.

---

## Quick Reference

| Error keyword | Likely cause | First step |
|--------------|--------------|-----------|
| `No valid credential` | Not logged in | `az login` |
| `Insufficient privileges` | Missing RBAC | Grant Contributor + UAA |
| `already taken` | Name collision | Change `name_prefix` |
| `max length` | Name too long | Shorten `name_prefix` |
| `forces replacement` | Immutable attr changed | Use `state mv` if possible |
| `state lock` | Stuck lock | `force-unlock` |
| `delegation` | Subnet missing delegation | Add `delegation` block to subnet |
| `mock-hub-vnet-id` | Dependency not applied | Apply platform stacks first |
