## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  type        = string
  description = "Azure Resouce Group Name"
}

variable "security_group_id" {
  type        = string
  description = "Microsoft Entra Security Group ID"
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault Name"
}

variable "bronze_bucket_name" {
  type        = string
  description = "Medallion Bronze Landing Zone (ADLS Bucket Name)"
}

variable "silver_bucket_name" {
  type        = string
  description = "Medallion Silver Landing Zone (ADLS Bucket Name)"
}

variable "gold_bucket_name" {
  type        = string
  description = "Medallion Gold Landing Zone (ADLS Bucket Name)"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "program_name" {
  type        = string
  description = "Program Name"
  default     = "dp-lessons"
}

variable "project_name" {
  type        = string
  description = "Project name for the data lake"
  default     = "ex-data-lake"
}

variable "azure_storage_account_kind" {
  type        = string
  description = "Azure Storage Account Kind"
  default     = "StorageV2"
}

variable "secret_permissions" {
  type        = list(string)
  description = "List of secret permissions to assign to the Key Vault"
  default = [
    "Get",
    "Delete"
  ]
}
