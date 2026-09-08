# infra/stacks/governance/rbac/main.tf
# R9: RBAC cross-subscription assignments
# Calls rbac-assignment module with the assignments map from env.hcl.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

module "rbac" {
  source = "../../../modules/rbac-assignment"

  assignments = var.rbac_assignments
}
