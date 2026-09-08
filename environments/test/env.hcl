# =============================================================================
# infra/environments/test/env.hcl
# Nguồn sự thật DUY NHẤT cho environment test.
# Mọi stack đọc file này qua:
#   read_terragrunt_config(find_in_parent_folders("env.hcl"))
# =============================================================================

locals {
  # ── Thông tin cơ bản ─────────────────────────────────────────────────────
  name_prefix  = "myproject"
  environment  = "test"
  location     = "southeastasia"

  # ── Subscription IDs ──────────────────────────────────────────────────────
  # Để trống "" cho CI validate. Điền subscription ID thực tế khi deploy.
  # Single-subscription: dùng cùng 1 ID cho tất cả.
  connectivity_subscription_id = ""
  management_subscription_id   = ""
  identity_subscription_id     = ""
  security_subscription_id     = ""
  app_subscription_id          = ""

  # ── Platform Feature Flags ────────────────────────────────────────────────
  deploy_management_groups = false   # Management Groups deploy 1 lần — tắt ở test
  deploy_connectivity      = true
  deploy_management        = true
  deploy_identity          = false
  deploy_security          = false

  # ── Connectivity Sub-Flags ────────────────────────────────────────────────
  deploy_firewall     = true
  deploy_vpn_gateway  = false
  deploy_dns_resolver = false
  deploy_bastion      = false

  # ── Application Feature Flags ─────────────────────────────────────────────
  deploy_aks        = true
  deploy_postgresql = true
  deploy_redis      = false
  # R2: deploy_service_bus thay thế deploy_apim cho Service Bus workload — đọc bởi workloads/service-bus/terragrunt.hcl
  deploy_service_bus = false  # Azure Service Bus Namespace trong application subscription
  deploy_apim        = false  # DEPRECATED: thay thế bởi deploy_service_bus
  # R1: VM Bastion workload flag (thay thế deploy_bastion dùng nhầm trước đây) — đọc bởi workloads/vm-bastion/terragrunt.hcl
  deploy_vm_bastion = false   # VM Bastion workload trong application subscription

  # ── Networking ────────────────────────────────────────────────────────────
  # CIDR scheme: hub=10.0/16, dev=10.1/16, test=10.2/16, uat=10.3/16, preprod=10.4/16, prod=10.5/16
  hub_address_space      = ["10.0.0.0/16"]
  app_vnet_address_space = ["10.2.0.0/16"]   # test = 10.2/16

  hub_subnets = {
    AzureFirewallSubnet      = { address_prefixes = ["10.0.0.0/26"] }
    GatewaySubnet            = { address_prefixes = ["10.0.0.64/27"] }
    DnsResolverInboundSubnet = { address_prefixes = ["10.0.0.96/28"] }
  }

  app_subnets = {
    default = { address_prefixes = ["10.2.1.0/24"] }
    data = {
      address_prefixes = ["10.2.2.0/24"]
      delegation = {
        name = "postgresql"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
    aks                = { address_prefixes = ["10.2.3.0/24"] }
    AzureBastionSubnet = { address_prefixes = ["10.2.255.0/26"] }
  }

  platform_mg_id    = ""
  application_mg_id = ""

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
