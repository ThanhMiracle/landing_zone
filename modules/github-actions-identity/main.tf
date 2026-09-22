terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# A dedicated identity keeps CI registry-write access separate from AKS and
# application workload identities. GitHub exchanges a short-lived OIDC token
# for this identity; no client secret or ACR admin credential is used.
resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name_prefix}-${var.environment}-github-actions-id"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "github-actions-acr-push"
    },
    var.tags
  )
}

resource "azurerm_federated_identity_credential" "github_actions" {
  name                = "github-actions-acr-push"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"

  # The subject is restricted to the repository and its deployment branch.
  subject = var.github_oidc_subject
}

resource "azurerm_role_assignment" "acr_push" {
  scope                            = var.container_registry_id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_user_assigned_identity.this.principal_id
  skip_service_principal_aad_check = true
}
