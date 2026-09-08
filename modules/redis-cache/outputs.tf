output "redis_id" {
  description = "The resource ID of the Redis cache"
  value       = azurerm_redis_cache.this.id
}

output "redis_hostname" {
  description = "The hostname of the Redis cache"
  value       = azurerm_redis_cache.this.hostname
}

output "redis_port" {
  description = "The SSL port of the Redis cache"
  value       = azurerm_redis_cache.this.ssl_port
}

output "primary_access_key" {
  description = "The primary access key for the Redis cache"
  value       = azurerm_redis_cache.this.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string for the Redis cache"
  value       = azurerm_redis_cache.this.primary_connection_string
  sensitive   = true
}
