# Runbook: Deployment

---

## Pre-deployment Checklist

```
□ az account show — đúng tenant và subscription
□ Tất cả TF_VAR_*_subscription_id đã được export
□ terragrunt run-all validate pass
□ terragrunt run-all plan đã được review
□ Không có unexpected destroy/replace trong plan
□ Approval từ senior nếu deploy lên uat/pre-production/prod
```

---

## Deploy toàn bộ (recommended)

```bash
cd infra

# 1. Validate — không cần Azure credentials (dùng mock outputs)
terragrunt run-all validate

# 2. Plan — review trước khi apply
terragrunt run-all plan

# 3. Apply — Terragrunt tự xử lý thứ tự: platform trước, environments sau
terragrunt run-all apply
```

---

## Deploy từng phần

### Chỉ platform

```bash
cd infra
terragrunt run-all plan  --terragrunt-include-dir platform
terragrunt run-all apply --terragrunt-include-dir platform
```

### Chỉ environments

```bash
cd infra
terragrunt run-all plan  --terragrunt-include-dir environments
terragrunt run-all apply --terragrunt-include-dir environments
```

### Một stack cụ thể

```bash
cd infra/environments/dev
terragrunt plan
terragrunt apply

# Hoặc platform
cd infra/platform/connectivity
terragrunt plan
terragrunt apply
```

---

## Thứ tự promote theo môi trường

```
dev → test → uat → pre-production → prod
```

Không apply lên prod khi chưa validate trên uat. Bật thêm modules dần theo sprint.

```bash
# Deploy dev trước
cd infra/environments/dev && terragrunt apply

# Sau khi dev stable, deploy test
cd infra/environments/test && terragrunt apply

# Lặp lại cho uat, pre-production, prod
```

---

## Targeted apply (dùng khi khẩn cấp)

```bash
cd infra/environments/dev
terragrunt apply -- -target=module.aks
```

> ⚠️ Targeted apply có thể tạo state inconsistency nếu resource có dependencies. Chỉ dùng khi thực sự cần, luôn chạy `terragrunt plan` sau để verify "No changes".

---

## Verify sau apply

```bash
# Xem outputs của stack
cd infra/environments/dev && terragrunt output

# Verify resource group
az group show --name "<name_prefix>-dev-rg"

# Verify Key Vault
az keyvault show --name "<name_prefix>-dev-kv" \
  --query "{name:name, rbacEnabled:properties.enableRbacAuthorization}"

# Verify VNet
az network vnet show \
  --name "<name_prefix>-dev-vnet" \
  --resource-group "<name_prefix>-dev-rg"

# Verify Log Analytics
az monitor log-analytics workspace show \
  --workspace-name "<name_prefix>-dev-log" \
  --resource-group "<name_prefix>-dev-rg"
```

---

## State file layout sau khi apply

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

State key được generate tự động từ folder path — không cần set thủ công.

---

## Rollback nhanh

```bash
# Option 1: Revert config
git checkout <old-commit> -- infra/environments/dev/
cd infra/environments/dev && terragrunt apply

# Option 2: Xem runbook đầy đủ
# docs/runbooks/rollback.md
```

---

## Ghi log deployment

Sau mỗi deployment lên uat/pre-production/prod:

```
Date:        YYYY-MM-DD
Environment: prod
Stack(s):    environments/prod, platform/connectivity
Deployed by: <tên>
Terraform:   x.x.x
Terragrunt:  x.x.x
Changes:     <mô tả ngắn>
Plan output: <link PR hoặc attachment>
Issues:      none / <mô tả nếu có>
```
