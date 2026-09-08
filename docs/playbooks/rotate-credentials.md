# Playbook: Rotating Secrets and Credentials

Hướng dẫn rotate credentials mà không gây downtime và không để lộ secret trong code.

---

## Nguyên tắc

- Secrets **không bao giờ** nằm trong `.tf` files hay git history
- Passwords được inject qua `TF_VAR_*` env vars hoặc lấy từ Key Vault
- Sau khi rotate, luôn verify service còn hoạt động trước khi xóa credential cũ

---

## 1. Rotate PostgreSQL Admin Password

### Bước 1 — Generate password mới

```bash
# Generate strong random password (32 chars, no special chars gây lỗi connection string)
NEW_PASSWORD=$(openssl rand -base64 24 | tr -d '=+/' | head -c 32)
echo "New password: $NEW_PASSWORD"  # lưu tạm, không commit
```

### Bước 2 — Inject qua env var và apply

```bash
export TF_VAR_postgresql_admin_password="$NEW_PASSWORD"

cd environments/<env>
terraform apply -var-file=terraform.tfvars
```

Terraform sẽ update password trên server.

### Bước 3 — Cập nhật Secret trong Key Vault

```bash
az keyvault secret set \
  --vault-name "<name_prefix>-<env>-kv" \
  --name "postgresql-admin-password" \
  --value "$NEW_PASSWORD"
```

### Bước 4 — Verify connection

```bash
# Test connection với password mới
psql "host=<server>.postgres.database.azure.com user=pgadmin dbname=postgres sslmode=require" \
  --command "SELECT 1;"
```

### Bước 5 — Notify team

Thông báo cho team rotate connection string trong ứng dụng nếu app dùng static credentials.

---

## 2. Rotate Key Vault Secrets (Application Secrets)

### Trường hợp: Secret đã set qua Terraform

```bash
# Rotate bằng Azure CLI (không cần terraform apply)
az keyvault secret set \
  --vault-name "<kv-name>" \
  --name "<secret-name>" \
  --value "<new-value>"
```

> Terraform module Key Vault dùng `lifecycle { ignore_changes = [value] }` nếu được cấu hình, nên `terraform apply` sau đó sẽ không overwrite giá trị mới.

### Trường hợp: Cần expire version cũ

```bash
# Disable version cũ
az keyvault secret set-attributes \
  --vault-name "<kv-name>" \
  --name "<secret-name>" \
  --version "<old-version-id>" \
  --enabled false
```

---

## 3. Rotate Azure Storage Account Access Key

Storage Account có 2 keys (`key1`, `key2`) — rotate từng cái để zero-downtime.

### Bước 1 — Lấy current key đang dùng

```bash
az storage account keys list \
  --account-name "<storage-account>" \
  --resource-group "<rg-name>"
```

### Bước 2 — Switch app sang key2 trước

Cập nhật connection string trong ứng dụng để dùng `key2`.

### Bước 3 — Rotate key1

```bash
az storage account keys renew \
  --account-name "<storage-account>" \
  --resource-group "<rg-name>" \
  --key key1
```

### Bước 4 — Cập nhật secret trong Key Vault

```bash
NEW_KEY=$(az storage account keys list \
  --account-name "<storage-account>" \
  --resource-group "<rg-name>" \
  --query "[?keyName=='key1'].value" -o tsv)

az keyvault secret set \
  --vault-name "<kv-name>" \
  --name "storage-key1" \
  --value "$NEW_KEY"
```

### Bước 5 — Switch app về key1, rotate key2

Lặp lại cho key2.

---

## 4. Rotate Service Principal / App Registration Secret

Nếu có Service Principal dùng trong CI/CD:

```bash
# Xem expiry của secret hiện tại
az ad app credential list \
  --id "<app-id>" \
  --query "[].{id:keyId, endDate:endDateTime}" -o table

# Thêm credential mới (chưa xóa cái cũ)
az ad app credential reset \
  --id "<app-id>" \
  --append  # quan trọng: --append để không xóa ngay
```

Cập nhật secret mới vào CI/CD (GitHub Secrets, Azure DevOps variable group) trước khi xóa credential cũ.

```bash
# Xóa credential cũ sau khi đã verify CI/CD hoạt động
az ad app credential delete \
  --id "<app-id>" \
  --key-id "<old-key-id>"
```

---

## 5. Rotate Managed Identity (không cần rotate)

User-Assigned Managed Identity **không có credentials để rotate** — đây là lý do chính để dùng MI thay SP. Azure tự quản lý token rotation.

Nếu MI bị compromise → revoke RBAC assignment, tạo MI mới:

```bash
# Tạo MI mới
az identity create \
  --name "<name_prefix>-<env>-id-new" \
  --resource-group "<rg-name>"

# Assign RBAC cho MI mới
az role assignment create \
  --assignee "<new-mi-principal-id>" \
  --role "Key Vault Secrets User" \
  --scope "<kv-resource-id>"

# Update Terraform để dùng MI mới, apply
# Sau khi verify → xóa MI cũ
```

---

## 6. Rotate Terraform State Backend Key

```bash
# Lấy key mới
NEW_KEY=$(az storage account keys list \
  --account-name "tfstate<project>" \
  --resource-group "rg-tfstate" \
  --query "[?keyName=='key1'].value" -o tsv)

# Update ARM_ACCESS_KEY trong môi trường / CI/CD
export ARM_ACCESS_KEY="$NEW_KEY"
```

---

## Schedule rotate gợi ý

| Credential | Frequency | Method |
|------------|-----------|--------|
| PostgreSQL password | 90 ngày | Terraform apply + Key Vault update |
| Key Vault secrets (app) | 180 ngày hoặc khi nghi ngờ lộ | Azure CLI |
| Storage Account key | 90 ngày | Rolling rotation (2 keys) |
| Service Principal secret | 12 tháng | Append new → update CI/CD → delete old |
| Managed Identity | Không cần | Azure quản lý tự động |
| Terraform state backend key | 90 ngày | Rolling rotation |
