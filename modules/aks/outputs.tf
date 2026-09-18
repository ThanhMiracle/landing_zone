output "cluster_id" {
  description = "The resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster. Sensitive — do not log."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "The Kubernetes API server host URL"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
}

output "client_certificate" {
  description = "Client certificate for authenticating to the cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate for the cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "The object ID of the kubelet managed identity (used for ACR pull RBAC)"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster. Consumed by diagnostic-settings module for target_resource_id."
  value       = azurerm_kubernetes_cluster.this.id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster. Used by downstream stacks for cluster configuration."
  value       = azurerm_kubernetes_cluster.this.name
}

output "key_vault_secrets_provider_client_id" {
  description = "Client ID of the managed identity created for the AKS Key Vault Secrets Store CSI add-on."
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "key_vault_secrets_provider_object_id" {
  description = "Object ID of the managed identity created for the AKS Key Vault Secrets Store CSI add-on."
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}
