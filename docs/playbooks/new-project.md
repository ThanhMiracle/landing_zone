# Playbook: Onboarding a New Client Project

Hướng dẫn cho Platform/DevOps engineer khi bắt đầu một engagement mới.

---

## Checklist nhanh

```
□ 1. Clone repo, tạo branch
□ 2. Chọn name_prefix (≤ 8 chars)
□ 3. Bootstrap state backend (1 lần / project)
□ 4. Cập nhật infra/terragrunt.hcl
□ 5. Set subscription IDs qua env vars
□ 6. Plan platform trước, environments sau
□ 7. Apply dev → test → uat → pre-production → prod
□ 8. Commit đúng files, không commit secrets
```

---

## Bước 1 — Clone và tạo branch

```bash
git clone <REPO_URL> infra
cd infra/infra
git checkout -b project/<customer-name>
```

Không làm việc trực tiếp trên `main`.

---

## Bước 2 — Chọn `name_prefix`

`name_prefix` xuất hiện trong **mọi** tên resource Azure.

Quy tắc:
- Lowercase, alphanumeric và dashes
- **Tối đa 8 ký tự** — Key Vault name `{prefix}-{env}-kv` giới hạn 24 chars
- Không dùng tên generic: `test`, `dev`, `azure`, `app`

Ví dụ: `acme`, `hpt`, `vib`, `tcb`, `mypj`

---

## Bước 3 — Bootstrap state backend

Chạy **một lần** cho toàn project, trước khi làm bất cứ điều gì khác:

```bash
PROJECT="acme"        # phải match name_prefix
LOCATION="southeastasia"

# Tạo Resource Group cho tfstate
az group create --name rg-tfstate --location $LOCATION

# Tạo Storage Account (tên globally unique)
az storage account create \
  --name "tfstate${PROJECT}" \
  --resource-group rg-tfstate \
  --location $LOCATION \
  --sku Standard_LRS \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Tạo container
az storage container create \
  --name tfstate \
  --account-name "tfstate${PROJECT}"
```

> Storage account name phải globally unique. Nếu `tfstate${PROJECT}` đã tồn tại, thêm suffix ngắn: `tfstateacme01`.

---

## Bước 4 — Cập nhật `infra/terragrunt.hcl`

```hcl
locals {
  project_name = "acme"          # ← đổi thành name_prefix của bạn

  connectivity_subscription_id = get_env("TF_VAR_connectivity_subscription_id", "")
  management_subscription_id   = get_env("TF_VAR_management_subscription_id", "")

  common_tags = {
    Project   = local.project_name
    ManagedBy = "terraform"
  }
}

remote_state {
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateacme"   # ← đổi thành tên storage account của bạn
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}
```

---

## Bước 5 — Set subscription IDs

### Single subscription (dev/demo/POC)

Set tất cả về cùng 1 subscription:

```bash
SUB="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

export TF_VAR_connectivity_subscription_id="$SUB"
export TF_VAR_management_subscription_id="$SUB"
export TF_VAR_dev_subscription_id="$SUB"
export TF_VAR_test_subscription_id="$SUB"
export TF_VAR_uat_subscription_id="$SUB"
export TF_VAR_pre_production_subscription_id="$SUB"
export TF_VAR_prod_subscription_id="$SUB"
```

### Multi subscription (enterprise)

```bash
export TF_VAR_connectivity_subscription_id="aaa..."  # hub VNet, Firewall
export TF_VAR_management_subscription_id="bbb..."    # Log Analytics, Defender
export TF_VAR_dev_subscription_id="ccc..."
export TF_VAR_test_subscription_id="ddd..."
export TF_VAR_uat_subscription_id="eee..."
export TF_VAR_pre_production_subscription_id="fff..."
export TF_VAR_prod_subscription_id="ggg..."
```

> **Tip:** Lưu vào `.env` file (không commit) và `source .env` mỗi session.

---

## Bước 6 — Plan và verify

```bash
cd infra

# Validate tất cả stacks (dùng mock outputs, không cần Azure)
terragrunt run-all validate

# Plan platform trước
terragrunt run-all plan --terragrunt-include-dir platform

# Review: hub_vnet_id, firewall, log_analytics workspace có đúng không

# Plan tất cả (environments dùng mock outputs vì platform chưa apply)
terragrunt run-all plan
```

---

## Bước 7 — Apply

```bash
cd infra

# Phase 1: platform (hub network + management)
terragrunt run-all apply --terragrunt-include-dir platform

# Phase 2: environments (tự nhận outputs từ platform)
terragrunt run-all apply --terragrunt-include-dir environments
```

Hoặc một lệnh duy nhất — Terragrunt tự xử lý thứ tự:

```bash
cd infra && terragrunt run-all apply
```

### Thứ tự promote theo environment

Không bật tất cả modules từ đầu. Tăng dần theo sprint:

| Sprint | Modules bật | Environments |
|--------|------------|--------------|
| 1 | Foundation only (VNet, RG, KV, Log Analytics) | dev |
| 2 | + compute (AKS/App Service) | dev, test |
| 3 | + database, messaging | dev, test, uat |
| 4 | + bastion, defender, APIM | uat, pre-production, prod |

Sửa feature flags trong `environments/{env}/variables.tf` hoặc qua `inputs` trong `terragrunt.hcl`.

---

## Bước 8 — Commit đúng files

```bash
# ✅ Commit
git add infra/terragrunt.hcl          # project config (không có secret)
git add infra/environments/*/terragrunt.hcl  # env configs
git add infra/platform/*/terragrunt.hcl
git add infra/**/.terraform.lock.hcl  # pin provider versions

# ❌ KHÔNG commit
# *.tfstate, *.tfstate.*
# .terraform/ directory
# .env file
# backend.tf, provider_generated.tf (auto-generated by Terragrunt)
# .terragrunt-cache/
```

---

## Bật module cho một environment cụ thể

Sửa `inputs` trong `infra/environments/{env}/terragrunt.hcl`:

```hcl
inputs = {
  workload_subscription_id = get_env("TF_VAR_dev_subscription_id", "")
  environment              = "dev"

  # Bật Bastion + PostgreSQL cho dev
  deploy_bastion    = true
  deploy_postgresql = true

  # ... các inputs khác tự động từ dependency
}
```

Sau đó:

```bash
cd infra/environments/dev
terragrunt plan   # preview
terragrunt apply  # deploy
```

---

## Naming convention

Với `name_prefix = "acme"`, `environment = "dev"`:

| Resource | Tên |
|----------|-----|
| Resource Group | `acme-dev-rg` |
| Key Vault | `acme-dev-kv` |
| VNet | `acme-dev-vnet` |
| Storage Account | `acmedevst` |
| Log Analytics | `acme-dev-log` |
| AKS | `acme-dev-aks` |

Xem đầy đủ tại [`docs/naming-convention.md`](../naming-convention.md).
