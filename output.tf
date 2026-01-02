output "azure_key_vault_id" {
  description = "Azure Key Vault ID"
  value       = module.azure_key_vault.key_vault_id
}

output "azure_key_vault_uri" {
  description = "Azure Key Vault URI"
  value       = module.azure_key_vault.key_vault_uri
}

output "azure_key_vault_key" {
  description = "Azure Key Vault Key"
  value       = module.azure_key_vault.key_vault_key
}

output "bronze_bucket_id" {
  description = "Azure Medallion Bronze Storage Bucket ID"
  value       = module.bronze_bucket.bucket_id
}

output "bronze_bucket_name" {
  description = "Azure Medallion Bronze Storage Bucket Name"
  value       = module.bronze_bucket.bucket_name
}

output "bronze_bucket_container_id" {
  description = "Azure Medallion Bronze Storage Bucket Container ID"
  value       = module.bronze_bucket.bucket_container_id
}

output "bronze_bucket_container_name" {
  description = "Azure Medallion Bronze Storage Bucket Container Name"
  value       = module.bronze_bucket.bucket_container_name
}

output "silver_bucket_id" {
  description = "Azure Medallion Silver Storage Bucket ID"
  value       = module.silver_bucket.bucket_id
}

output "silver_bucket_name" {
  description = "Azure Medallion Silver Storage Bucket Name"
  value       = module.silver_bucket.bucket_name
}

output "silver_bucket_container_id" {
  description = "Azure Medallion Silver Storage Bucket Container ID"
  value       = module.silver_bucket.bucket_container_id
}

output "silver_bucket_container_name" {
  description = "Azure Medallion Silver Storage Bucket Container Name"
  value       = module.silver_bucket.bucket_container_name
}

output "gold_bucket_id" {
  description = "Azure Medallion Gold Storage Bucket ID"
  value       = module.gold_bucket.bucket_id
}

output "gold_bucket_name" {
  description = "Azure Medallion Gold Storage Bucket Name"
  value       = module.gold_bucket.bucket_name
}

output "gold_bucket_container_id" {
  description = "Azure Medallion Gold Storage Bucket Container ID"
  value       = module.gold_bucket.bucket_container_id
}

output "gold_bucket_container_name" {
  description = "Azure Medallion Gold Storage Bucket Container Name"
  value       = module.gold_bucket.bucket_container_name
}
