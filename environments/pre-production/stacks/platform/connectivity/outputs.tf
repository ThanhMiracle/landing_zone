# =============================================================================
# infra/stacks/platform/connectivity/outputs.tf
# Outputs consumed by downstream stacks via Terragrunt dependency blocks:
#   - baseline stack: hub_vnet_id, firewall_private_ip, hub_resource_group_name, dns_server_ip
# =============================================================================

output "hub_vnet_id" {
  value       = module.hub_vnet.vnet_id
  description = "Resource ID of the hub VNet. Consumed by workload vnet-peering module and baseline stack."
}

output "firewall_private_ip" {
  value       = var.deploy_firewall ? module.firewall[0].firewall_private_ip : null
  description = "Private IP of Azure Firewall. Consumed by workload forced-tunneling route table. Null when deploy_firewall = false."
}

output "firewall_public_ip" {
  value       = var.deploy_firewall ? module.firewall[0].firewall_public_ip : null
  description = "Public IP of Azure Firewall. Null when deploy_firewall = false."
}

output "hub_resource_group_name" {
  value       = module.resource_group.name
  description = "Resource group name of the hub networking resources. Required for cross-subscription VNet peering."
}

output "dns_server_ip" {
  value       = var.deploy_dns_resolver ? module.dns_resolver[0].inbound_endpoint_ip : null
  description = "DNS Resolver inbound endpoint IP. Used as custom DNS server for spoke VNets. Null when deploy_dns_resolver = false."
}

output "log_analytics_workspace_id" {
  value       = null
  description = "Log Analytics Workspace ID. Reserved for future diagnostic settings integration in this stack. Currently null — workspace is managed by the management stack."
}
