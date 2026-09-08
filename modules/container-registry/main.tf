terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Azure Container Registry
#
# Authentication pattern — Managed Identity (recommended):
#   Admin credentials are disabled by design. Grant access by assigning
#   built-in ACR roles to the workload's Managed Identity via the
#   rbac-assignment module:
#
#     AcrPull  — read images (e.g. AKS node pool, Function App, App Service)
#     AcrPush  — push images (e.g. CI/CD pipeline's MI)
#
#   Example:
#     module "acr_pull_assignment" {
#       source = "../../modules/rbac-assignment"
#       assignments = {
#         acr_pull = {
#           principal_id         = module.managed_identity.principal_id
#           role_definition_name = "AcrPull"
#           scope                = module.container_registry.registry_id
#         }
#       }
#     }
# ---------------------------------------------------------------------------

resource "azurerm_container_registry" "this" {
  # Naming: {name_prefix}{environment}acr — no dashes, lowercase
  name                = lower("${var.name_prefix}${var.environment}acr")
  resource_group_name = var.resource_group_name
  location            = var.location

  sku = var.sku

  # Admin user disabled — use Managed Identity for authentication (see note above)
  admin_enabled = false

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
