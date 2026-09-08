# Onboarding Checklist — New Project

Step-by-step để deploy baseline environment từ zero với Terragrunt.

---

## Prerequisites

- [ ] **Terraform** `>= 1.9.0` — `terraform version`
- [ ] **Terragrunt** `>= 0.50.0` — `terragrunt --version`
- [ ] **Azure CLI** — `az version`
- [ ] Azure subscription với `Contributor` + `User Access Administrator`
- [ ] Access to this repository

---

## Phase 1 — Bootstrap State Backend (chạy 1 lần / project)

```bash
PROJECT="myproject"   # match name_prefix, tối đa 8 chars
LOCATION="southeastasia"

# Resource Group cho tfstate
az group create --name rg-tfstate --location $LOCATION

# Storage Account (globally unique)
az storage account create \
  --name "tfstate${PROJECT}" \
  --resource-group rg-tfstate \
  --location $LOCATION \
  --sku Standard_LRS \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Container
az storage container create \
  --name tfstate \
  --account-name "tfstate${PROJECT}"
```

- [ ] Ghi lại: `storage_account_name = "tfstate${PROJECT}"`

---

## Phase 2 — Cấu hình Root Terragrunt

- [ ] Clone repo:
  ```bash
  git clone <REPO_URL> && cd infra/infra
  ```

- [ ] Sửa `infra/terragrunt.hcl`:
  ```hcl
  locals {
    project_name = "myproject"        # ← tên project của bạn
  }
  remote_state {
    config = {
      storage_account_name = "tfstatemyproject"  # ← storage account vừa tạo
      resource_group_name  = "rg-tfstate"
      container_name       = "tfstate"
      key = "${path_relative_to_include()}/terraform.tfstate"
    }
  }
  ```

---

## Phase 3 — Set Subscription IDs

- [ ] Export subscription IDs:
  ```bash
  # Single subscription (dev/demo)
  SUB="<your-subscription-id>"
  export TF_VAR_connectivity_subscription_id="$SUB"
  export TF_VAR_management_subscription_id="$SUB"
  export TF_VAR_dev_subscription_id="$SUB"
  export TF_VAR_test_subscription_id="$SUB"
  export TF_VAR_uat_subscription_id="$SUB"
  export TF_VAR_pre_production_subscription_id="$SUB"
  export TF_VAR_prod_subscription_id="$SUB"
  ```

- [ ] Verify: `az account show`

---

## Phase 4 — Validate

- [ ] Validate tất cả stacks (không cần Azure — dùng mock outputs):
  ```bash
  cd infra && terragrunt run-all validate
  # Expected: All stacks: Success! The configuration is valid.
  ```

---

## Phase 5 — Plan

- [ ] Plan platform:
  ```bash
  cd infra && terragrunt run-all plan --terragrunt-include-dir platform
  ```
  Review: hub VNet, Firewall, Log Analytics workspace sẽ được tạo.

- [ ] Plan tất cả:
  ```bash
  cd infra && terragrunt run-all plan
  ```
  Environments sẽ show `hub_vnet_id = "mock-hub-vnet-id"` — bình thường, platform chưa apply.

---

## Phase 6 — Apply

- [ ] Deploy platform trước:
  ```bash
  cd infra && terragrunt run-all apply --terragrunt-include-dir platform
  ```

- [ ] Deploy environments (tự nhận outputs từ platform):
  ```bash
  cd infra && terragrunt run-all apply --terragrunt-include-dir environments
  ```

- [ ] Hoặc một lệnh duy nhất:
  ```bash
  cd infra && terragrunt run-all apply
  ```

---

## Phase 7 — Verify

- [ ] Xem outputs:
  ```bash
  cd infra/environments/dev && terragrunt output
  ```

- [ ] Kiểm tra Azure Portal:
  - [ ] Resource Group `myproject-dev-rg` tồn tại
  - [ ] Key Vault `myproject-dev-kv` tồn tại, RBAC mode bật
  - [ ] VNet `myproject-dev-vnet` tồn tại
  - [ ] Log Analytics `myproject-dev-log` tồn tại
  - [ ] Hub VNet peering tồn tại (nếu multi-sub)

---

## Phase 8 — Bật thêm modules theo nhu cầu

Sửa `inputs` trong `infra/environments/dev/terragrunt.hcl`:

```hcl
inputs = {
  workload_subscription_id = get_env("TF_VAR_dev_subscription_id", "")
  environment              = "dev"

  # Bật modules cần thiết
  deploy_aks        = true
  deploy_bastion    = true
  deploy_postgresql = true

  # ... platform outputs tự động từ dependency blocks
}
```

Sau đó:
```bash
cd infra/environments/dev && terragrunt apply
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `No valid credential sources` | `az login` |
| `hub_vnet_id = mock-hub-vnet-id` sau apply | Platform chưa apply — chạy platform trước |
| Storage account name conflict | Thêm suffix: `tfstatemyproject01` |
| Key Vault name > 24 chars | Rút ngắn `name_prefix` xuống ≤ 6 chars |
| State lock stuck | `terragrunt force-unlock <LOCK_ID>` |

Chi tiết tại [`docs/troubleshooting.md`](troubleshooting.md).
