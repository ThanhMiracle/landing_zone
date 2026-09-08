# Landing Zone Guide

> ℹ️ Repo này đã chuyển sang Terragrunt làm deployment tool duy nhất.
> Hub-spoke networking, Azure Firewall và DNS Resolver được deploy qua `infra/platform/connectivity/`.

---

## Tài liệu liên quan

- **Tổng quan kiến trúc + deployment**: [`docs/terragrunt-caf-guide.md`](terragrunt-caf-guide.md)
- **Bắt đầu từ zero**: [`docs/onboarding-checklist.md`](onboarding-checklist.md)
- **Onboard project mới**: [`docs/playbooks/new-project.md`](playbooks/new-project.md)
- **Vận hành deploy**: [`docs/runbooks/deploy.md`](runbooks/deploy.md)

---

## Hub-Spoke Topology

```
platform/connectivity/          ← hub subscription
  ├── Hub VNet (10.0.0.0/16)
  │   ├── AzureFirewallSubnet   (10.0.0.0/26)
  │   ├── GatewaySubnet         (10.0.0.64/27)
  │   └── DnsResolverInboundSubnet (10.0.0.96/28)
  ├── Azure Firewall
  ├── VPN Gateway (optional)
  └── DNS Resolver (optional)

environments/{env}/             ← workload subscriptions
  ├── Spoke VNet
  ├── VNet Peering → Hub (cross-subscription)
  ├── Route Table (forced tunneling 0.0.0.0/0 → Firewall)
  └── Workloads (AKS, PostgreSQL, Redis, etc.)
```

**AzureBastionSubnet được exclude khỏi forced tunneling** — Bastion cần internet trực tiếp để hoạt động.

---

## Deploy Hub-Spoke

```bash
# 1. Set subscription IDs
export TF_VAR_connectivity_subscription_id="<hub-sub>"
export TF_VAR_dev_subscription_id="<dev-sub>"
# ...

# 2. Deploy platform (hub) trước
cd infra && terragrunt run-all apply --terragrunt-include-dir platform

# 3. Deploy environments (spoke) — tự peer về hub
cd infra && terragrunt run-all apply --terragrunt-include-dir environments
```

Hub VNet ID và Firewall IP tự flow vào spoke qua `dependency` blocks — không cần copy-paste.

---

## Feature Flags cho Hub Connectivity

Trong `infra/environments/{env}/terragrunt.hcl`:

```hcl
inputs = {
  # Bật hub peering (cần hub_vnet_id từ platform/connectivity)
  deploy_hub_peering    = true

  # Bật forced tunneling qua Firewall
  deploy_forced_tunneling = true

  # Bật Bastion trong spoke
  deploy_bastion = true

  # Values này tự động từ dependency, không cần điền tay:
  hub_vnet_id         = dependency.connectivity.outputs.hub_vnet_id
  firewall_private_ip = dependency.connectivity.outputs.firewall_private_ip
}
```
