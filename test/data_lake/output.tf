output "bronze_bucket_name" {
  description = "Azure Medallion Bronze Storage Bucket Name"
  value       = module.data_lake.bronze_bucket_name
}

output "bronze_bucket_container_name" {
  description = "Azure Medallion Bronze Storage Bucket Container Name"
  value       = module.data_lake.bronze_bucket_container_name
}

output "silver_bucket_name" {
  description = "Azure Medallion Silver Storage Bucket Name"
  value       = module.data_lake.silver_bucket_name
}

output "silver_bucket_container_name" {
  description = "Azure Medallion Silver Storage Bucket Container Name"
  value       = module.data_lake.silver_bucket_container_name
}

output "gold_bucket_name" {
  description = "Azure Medallion Gold Storage Bucket Name"
  value       = module.data_lake.gold_bucket_name
}

output "gold_bucket_container_name" {
  description = "Azure Medallion Gold Storage Bucket Container Name"
  value       = module.data_lake.gold_bucket_container_name
}