# =============================================================================
# infra/environments/dev/env.hcl
# Nguồn sự thật DUY NHẤT cho environment dev.
# Mọi stack đọc file này qua:
#   read_terragrunt_config(find_in_parent_folders("env.hcl"))
# =============================================================================

locals {
  # ── Thông tin cơ bản ─────────────────────────────────────────────────────
  # name_prefix: lowercase, tối đa 10 ký tự (giới hạn Azure naming)
  name_prefix = "thanhproject"
  environment = "dev"
  location    = "japanwest"

  # ── Subscription IDs (R10.3) ──────────────────────────────────────────────
  # Điền bằng Azure Subscription ID thực tế hoặc để trống "" cho CI validate.
  # Mỗi platform subscription nên là subscription riêng biệt theo CAF.
  # Với môi trường dev đơn giản: có thể dùng cùng 1 subscription cho tất cả.
  connectivity_subscription_id = "223b3cc4-6941-480a-81ec-4825adcd8b0e" # Sub cho Hub VNet, Firewall, VPN, DNS
  management_subscription_id   = "223b3cc4-6941-480a-81ec-4825adcd8b0e" # Sub cho Log Analytics, Defender
  identity_subscription_id     = "223b3cc4-6941-480a-81ec-4825adcd8b0e" # Sub cho Entra ID, AD DS (scaffold)
  security_subscription_id     = "223b3cc4-6941-480a-81ec-4825adcd8b0e" # Sub cho Sentinel, Security Center (scaffold)
  app_subscription_id          = "223b3cc4-6941-480a-81ec-4825adcd8b0e" # Sub cho workload applications

  # ── Platform Feature Flags (R10.4) ────────────────────────────────────────
  # Bật/tắt từng platform stack mà không thay đổi code.
  deploy_management_groups = false # Deploy Management Group hierarchy
  deploy_connectivity      = true  # Deploy Hub VNet, Firewall, DNS, VPN
  deploy_management        = true  # Deploy Log Analytics, Defender
  deploy_identity          = false # Scaffold only — tắt mặc định (R6, R10.10)
  deploy_security          = false # Scaffold only — tắt mặc định (R7, R10.10)

  # ── Connectivity Sub-Flags (R10.5) ────────────────────────────────────────
  # Sub-flags của Connectivity stack — chỉ có hiệu lực khi deploy_connectivity = true.
  deploy_firewall     = true  # Azure Firewall (cần cho forced tunneling)
  deploy_vpn_gateway  = false # VPN Gateway (tốn ~3h để tạo — chỉ bật khi cần)
  deploy_dns_resolver = false # Private DNS Resolver
  deploy_bastion      = false # Azure Bastion trong hub

  # ── Application Feature Flags (R10.6) ─────────────────────────────────────
  # Bật/tắt từng workload template mà không thay đổi code.
  deploy_aks          = true  # AKS cluster trong application subscription
  deploy_postgresql   = true  # PostgreSQL Flexible Server
  deploy_redis        = false # Azure Cache for Redis
  deploy_blob_storage = true  # Private Blob container for data written by AKS workloads
  # R2: deploy_service_bus thay thế deploy_apim cho Service Bus workload — đọc bởi workloads/service-bus/terragrunt.hcl
  deploy_service_bus = false # Azure Service Bus Namespace trong application subscription
  deploy_apim        = false # DEPRECATED: thay thế bởi deploy_service_bus
  # R1: VM Bastion workload flag (thay thế deploy_bastion dùng nhầm trước đây) — đọc bởi workloads/vm-bastion/terragrunt.hcl
  deploy_vm_bastion = false # VM Bastion workload trong application subscription

  # ── Networking (R10.7) ────────────────────────────────────────────────────
  # CIDR scheme: hub=10.0/16, dev=10.1/16, staging=10.2/16, prod=10.5/16
  # Các CIDRs PHẢI không overlap trong toàn hub environment.
  hub_address_space      = ["10.0.0.0/16"] # Hub VNet (Connectivity stack)
  app_vnet_address_space = ["10.1.0.0/16"] # Spoke VNet (Baseline stack)

  # Kubernetes service addresses must not overlap the hub or spoke networks.
  aks_service_cidr   = "172.20.0.0/16"
  aks_dns_service_ip = "172.20.0.10"

  # ── Hub Subnets (cho Connectivity stack) ──────────────────────────────────
  # AzureFirewallSubnet: /26 minimum
  # GatewaySubnet: /27 minimum
  # DnsResolverInboundSubnet: /28 minimum
  hub_subnets = {
    AzureFirewallSubnet      = { address_prefixes = ["10.0.0.0/26"] }
    GatewaySubnet            = { address_prefixes = ["10.0.0.64/27"] }
    DnsResolverInboundSubnet = { address_prefixes = ["10.0.0.96/28"] }
  }

  # ── Spoke Subnets (cho Baseline stack) ───────────────────────────────────
  app_subnets = {
    default = { address_prefixes = ["10.1.1.0/24"] }
    data = {
      address_prefixes = ["10.1.2.0/24"]
      # Preserve the endpoint PostgreSQL needs for Storage/WAL traffic.
      service_endpoints = ["Microsoft.Storage"]
      delegation = {
        name = "postgresql"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
    aks                = { address_prefixes = ["10.1.3.0/24"] }
    AzureBastionSubnet = { address_prefixes = ["10.1.255.0/26"] }
  }

  # ── Management Group IDs (R3 — điền sau khi management-groups stack deploy)
  # Để trống cho lần đầu deploy; sau khi stack management-groups chạy xong,
  # các IDs này được populate tự động qua dependency outputs.
  platform_mg_id    = "" # /providers/Microsoft.Management/managementGroups/...
  application_mg_id = "" # /providers/Microsoft.Management/managementGroups/...

  # ── Tags chung ────────────────────────────────────────────────────────────
  common_tags = {
    Project     = local.name_prefix
    Environment = local.environment
    ManagedBy   = "terraform"
  }

  # ── Governance Feature Flags (Sprint 3) ───────────────────────────────────
  # Kiểm soát governance/rbac stack. Bật khi muốn gán roles cross-subscription.
  deploy_rbac = false

  # RBAC assignments map — điền principal_id thực tế khi triển khai.
  # Empty string principal_id hợp lệ cho CI validate.
  rbac_assignments = {
    network_team_connectivity = {
      principal_id         = ""
      role_definition_name = "Network Contributor"
      scope                = "/subscriptions/${local.connectivity_subscription_id}"
    }
    ops_team_management = {
      principal_id         = ""
      role_definition_name = "Monitoring Contributor"
      scope                = "/subscriptions/${local.management_subscription_id}"
    }
  }

  # Kiểm soát Azure AD DS trong platform/identity stack. Chỉ có hiệu lực khi deploy_identity = true.
  deploy_identity_ds = false

  # Kiểm soát Microsoft Sentinel onboarding trong platform/security stack. Chỉ có hiệu lực khi deploy_security = true.
  deploy_sentinel = false

  # Kiểm soát Defender for Cloud pricing plans trong platform/security stack. Chỉ có hiệu lực khi deploy_security = true.
  deploy_defender_plans = false
}
