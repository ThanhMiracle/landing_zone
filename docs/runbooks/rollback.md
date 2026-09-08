# Runbook: Rollback

Hướng dẫn xử lý khi deployment thất bại hoặc cần revert thay đổi.

---

## Mức độ rollback

| Tình huống | Phương án |
|-----------|-----------|
| Apply chưa xong, bị interrupt | Rerun `terraform apply` — Terraform idempotent |
| Apply xong nhưng app lỗi | Revert code thay đổi → re-apply |
| Config sai, cần revert một module | `terraform apply -target` với config cũ |
| Cần revert toàn bộ environment về phiên bản cũ | Git checkout + terraform apply |
| Resource bị xóa nhầm | `terraform import` + re-apply |

---

## Trường hợp 1: Apply bị interrupt giữa chừng

Terraform ghi state sau mỗi resource operation. Nếu bị interrupt, một số resources đã tạo, một số chưa.

```bash
# Chỉ cần chạy lại — Terraform tiếp tục từ chỗ dừng
terraform apply -var-file=terraform.tfvars
```

Không cần làm gì thêm. Terraform so sánh state với thực tế và chỉ tạo phần còn thiếu.

---

## Trường hợp 2: Revert config về commit cũ

```bash
# Xem history
git log --oneline environments/<env>/

# Checkout version cũ của config files
git checkout <commit-hash> -- environments/<env>/

# Apply config cũ
cd environments/<env>
terragrunt plan
# Review plan — confirm nó revert đúng thứ cần revert
terraform apply rollback.tfplan

# Sau khi rollback xong, restore HEAD cho git tracking
git checkout HEAD -- environments/<env>/
```

---

## Trường hợp 3: Revert một module cụ thể

```bash
# Ví dụ: revert Key Vault config về trạng thái cũ
git checkout <old-commit> -- environments/<env>/security.tf

terraform plan -target=module.key_vault -var-file=terraform.tfvars
# Review plan
terraform apply -target=module.key_vault -var-file=terraform.tfvars
```

---

## Trường hợp 4: Resource bị xóa nhầm bằng `terraform destroy`

Nếu resource đã tồn tại trong Azure nhưng bị xóa khỏi state, cần `terraform import`:

```bash
# Ví dụ: reimport Resource Group
terraform import \
  module.resource_group.azurerm_resource_group.this \
  "/subscriptions/<sub-id>/resourceGroups/<rg-name>"

# Ví dụ: reimport Key Vault
terraform import \
  module.key_vault.azurerm_key_vault.this \
  "/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<kv-name>"

# Sau khi import, verify state
terraform plan -var-file=terraform.tfvars
# Expected: No changes (resource đã import đúng config)
```

### Tìm resource ID để import

```bash
# Resource Group
az group show --name "<rg-name>" --query id -o tsv

# Key Vault
az keyvault show --name "<kv-name>" --resource-group "<rg-name>" --query id -o tsv

# VNet
az network vnet show --name "<vnet-name>" --resource-group "<rg-name>" --query id -o tsv

# Storage Account
az storage account show --name "<account-name>" --resource-group "<rg-name>" --query id -o tsv
```

---

## Trường hợp 5: Key Vault bị xóa (soft delete)

Key Vault có soft delete — không bị xóa hẳn ngay, còn trong trạng thái "deleted" 90 ngày.

```bash
# Kiểm tra Key Vault đã xóa
az keyvault list-deleted --query "[].{name:name, scheduledPurgeDate:properties.scheduledPurgeDate}"

# Recover Key Vault
az keyvault recover --name "<kv-name>"

# Import lại vào Terraform state
terraform import \
  module.key_vault.azurerm_key_vault.this \
  "/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<kv-name>"
```

---

## Trường hợp 6: Terraform state bị corrupt

**KHÔNG chạy `terraform apply` khi state corrupt.** Kiểm tra state trước:

```bash
# Xem state hiện tại
terraform state list

# Pull state về local để inspect
terraform state pull > state-backup-$(date +%Y%m%d).json

# Nếu state lỗi nhưng Azure resources còn đó → remove resource bị corrupt khỏi state
terraform state rm <resource-address>
# Sau đó import lại
terraform import <resource-address> <azure-resource-id>
```

Azure Blob Storage tự động lưu **version history** của state file. Nếu cần restore state cũ:

```bash
# List versions
az storage blob list \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --prefix "environments/<env>/terraform.tfstate" \
  --query "[].{name:name, lastModified:properties.lastModified}" \
  --include v  # include versions

# Download version cũ
az storage blob download \
  --account-name "tfstate<project>" \
  --container-name tfstate \
  --name "environments/<env>/terraform.tfstate" \
  --version-id "<version-id>" \
  --file terraform.tfstate.bak

# Inspect và quyết định có restore không
# Để restore: upload lại file đó thành current version
```

---

## Rollback v?i Terragrunt

```bash
# Rollback một stack
cd infra/environments/dev
git checkout <old-commit> -- .
terragrunt plan
# Review
terragrunt apply

# Rollback toàn bộ (cẩn thận — ảnh hưởng tất cả envs)
cd infra
git checkout <old-commit> -- environments/
terragrunt run-all plan --terragrunt-include-dir environments
# Review từng stack
terragrunt run-all apply --terragrunt-include-dir environments
```

---

## Post-rollback checklist

```
□ terraform plan sau rollback cho thấy "No changes" (stable state)
□ Azure Portal verify resource ở trạng thái expected
□ Application health check pass
□ Ghi log rollback: nguyên nhân, phương án, thời gian
□ Tạo post-mortem nếu ảnh hưởng production
```
