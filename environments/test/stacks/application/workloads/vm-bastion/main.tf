# =============================================================================
# infra/stacks/application/workloads/vm-bastion/main.tf
#
# Workload stack: deploys one Linux VM (jump-box / admin VM) together with
# an Azure Bastion Host for secure, browser-based SSH/RDP access.
#
# Dependencies (via terragrunt.hcl):
#   - baseline stack  → spoke_vnet_id, spoke_resource_group_name,
#                        key_vault_id, managed_identity_id
#
# Provider alias: azurerm.workload  (app_subscription_id)
# Naming:  ${var.name_prefix}-${var.environment}-vm
#          ${var.name_prefix}-${var.environment}-bastion
# =============================================================================

# ---------------------------------------------------------------------------
# Data sources — resolve subnet IDs from the spoke VNet
# ---------------------------------------------------------------------------

# The spoke VNet name is derived from the standard naming convention used in
# the baseline stack: {name_prefix}-{environment}-vnet
data "azurerm_virtual_network" "spoke" {
  provider            = azurerm.workload
  name                = "${var.name_prefix}-${var.environment}-vnet"
  resource_group_name = var.spoke_resource_group_name
}

# Default subnet — used by the VM NIC
data "azurerm_subnet" "default" {
  provider             = azurerm.workload
  name                 = "default"
  virtual_network_name = data.azurerm_virtual_network.spoke.name
  resource_group_name  = var.spoke_resource_group_name
}

# AzureBastionSubnet — Azure Bastion requires a subnet named exactly
# 'AzureBastionSubnet' with a /26 or larger prefix (defined in env.hcl app_subnets)
data "azurerm_subnet" "bastion" {
  provider             = azurerm.workload
  name                 = "AzureBastionSubnet"
  virtual_network_name = data.azurerm_virtual_network.spoke.name
  resource_group_name  = var.spoke_resource_group_name
}

# ---------------------------------------------------------------------------
# Module: virtual-machine
# Deploys a Linux VM (Ubuntu 22.04 LTS) with a system-assigned identity and
# a user-assigned managed identity for Azure service authentication.
# ---------------------------------------------------------------------------
module "vm" {
  source = "../../../../modules/virtual-machine"

  providers = {
    azurerm = azurerm.workload
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = var.spoke_resource_group_name

  # Place the VM NIC in the default subnet of the spoke VNet
  subnet_id = data.azurerm_subnet.default.id

  # VM sizing — default Standard_D2s_v3 (override via tfvars if needed)
  vm_size = "Standard_D2s_v3"

  # SSH authentication — ssh_public_key is a required variable on the module;
  # retrieve the stored public key from Key Vault in a real deployment by
  # referencing the data source below, or pass a value via a tfvars override.
  # For scaffold purposes a placeholder is used — replace with real key value.
  admin_username = "azureuser"
  ssh_public_key = "placeholder-replace-with-real-ssh-public-key"

  # OS disk — SSD for better performance on a bastion/admin VM
  os_disk_type = "StandardSSD_LRS"

  # Mandatory tags
  tags = merge(var.tags, {
    Workload = "vm-bastion"
    Role     = "jumpbox"
  })
}

# ---------------------------------------------------------------------------
# Module: bastion
# Deploys an Azure Bastion Host into the AzureBastionSubnet.
# Provides secure browser-based RDP/SSH to VMs without exposing public IPs.
# ---------------------------------------------------------------------------
module "bastion" {
  source = "../../../../modules/bastion"

  providers = {
    azurerm = azurerm.workload
  }

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = var.spoke_resource_group_name

  # Bastion MUST use a subnet named exactly 'AzureBastionSubnet' (/26 minimum)
  subnet_id = data.azurerm_subnet.bastion.id

  # Basic SKU is sufficient for standard SSH/RDP tunneling; use Standard for
  # shareable links, IP-based connections, or file copy features.
  sku = "Basic"

  # Mandatory tags
  tags = merge(var.tags, {
    Workload = "vm-bastion"
    Role     = "bastion"
  })
}
