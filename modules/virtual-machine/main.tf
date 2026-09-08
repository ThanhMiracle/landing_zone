terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Locals — common tags
# ---------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------
# Network Interface
# Naming: {name_prefix}-{environment}-nic
# ---------------------------------------------------------------------------

resource "azurerm_network_interface" "this" {
  name                = "${var.name_prefix}-${var.environment}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Linux Virtual Machine
# Naming: {name_prefix}-{environment}-vm
#
# Security decisions:
#   - SSH key authentication only (disable_password_authentication = true)
#   - System-assigned Managed Identity enabled
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "this" {
  name                = "${var.name_prefix}-${var.environment}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location

  size           = var.vm_size
  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  # SSH key authentication only — passwords are disabled
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # System-assigned Managed Identity
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Optional Managed Data Disks
# Created via for_each on var.data_disks map
# ---------------------------------------------------------------------------

resource "azurerm_managed_disk" "this" {
  for_each = var.data_disks

  name                = "${var.name_prefix}-${var.environment}-disk-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb

  tags = local.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = each.value.lun
  caching            = "ReadWrite"
}
