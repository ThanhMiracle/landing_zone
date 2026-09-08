# infra/stacks/application/workloads/redis/outputs.tf

output "redis_id" {
  description = "The resource ID of the Azure Cache for Redis instance."
  value       = module.redis.redis_id
}

output "redis_hostname" {
  description = "The hostname of the Azure Cache for Redis instance. Used by applications to connect."
  value       = module.redis.redis_hostname
}

output "redis_primary_access_key" {
  description = "The primary access key for the Azure Cache for Redis instance. Treat as a secret."
  value       = module.redis.primary_access_key
  sensitive   = true
}
