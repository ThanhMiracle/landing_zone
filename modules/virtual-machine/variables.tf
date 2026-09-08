# ---------------------------------------------------------------------------
# Standard variables — present on every module
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Short prefix for all resource names (e.g. 'myapp'). Combined with environment to form resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. 'dev', 'prod'). Used in resource names and mandatory tags."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group in which to create the VM and related resources."
  type        = string
}

variable "location" {
  description = "Azure region for the resources (e.g. 'southeastasia')."
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to merge with the mandatory Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "subnet_id" {
  description = "Resource ID of the subnet to attach the Network Interface to. Required — the VM must be placed in a subnet."
  type        = string
}

# ---------------------------------------------------------------------------
# VM sizing
# ---------------------------------------------------------------------------

variable "vm_size" {
  description = "Azure VM size / SKU (e.g. 'Standard_D2s_v3', 'Standard_B2s'). See https://docs.microsoft.com/azure/virtual-machines/sizes for available sizes."
  type        = string
  default     = "Standard_D2s_v3"
}

# ---------------------------------------------------------------------------
# Authentication — SSH keys only (passwords disabled)
# ---------------------------------------------------------------------------

variable "admin_username" {
  description = "Username for the local administrator account on the VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key to authorize for the admin user (e.g. the output of 'cat ~/.ssh/id_rsa.pub'). Password authentication is disabled — this is required."
  type        = string
}

# ---------------------------------------------------------------------------
# OS Disk
# ---------------------------------------------------------------------------

variable "os_disk_type" {
  description = "Storage account type for the OS disk. Allowed values: 'Standard_LRS', 'StandardSSD_LRS', 'Premium_LRS'."
  type        = string
  default     = "StandardSSD_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "os_disk_type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS."
  }
}

# ---------------------------------------------------------------------------
# Source image reference
# ---------------------------------------------------------------------------

variable "source_image_reference" {
  description = "Marketplace image reference for the VM OS. Defaults to Ubuntu Server 22.04 LTS."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ---------------------------------------------------------------------------
# Optional data disks
# ---------------------------------------------------------------------------

variable "data_disks" {
  description = "Map of managed data disks to create and attach to the VM. Each key becomes part of the disk name. lun must be unique per disk (0–63)."
  type = map(object({
    disk_size_gb         = number
    lun                  = number
    storage_account_type = string
  }))
  default = {}
}
