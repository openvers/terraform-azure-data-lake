## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  type        = string
  description = "Azure Resouce Group Name"
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "sku_name" {
  type        = string
  description = "Key Vault SKU name"
  default     = "standard"
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain soft deleted keys"
  default     = 90
}

variable "enable_for_disk_encryption" {
  type        = bool
  description = "Flag to enable disk encryption"
  default     = true
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Flag to enable purge protection"
  default     = true
}

variable "secret_permissions" {
  type        = list(string)
  description = "List of secret permissions to assign to the Key Vault"
  default     = ["Get"]
}

variable "key_permissions" {
  type        = list(string)
  description = "List of key permissions to assign to the Key Vault"
  default = [
    "Get",
    "Create",
    "Delete",
    "List",
    "Restore",
    "Recover",
    "UnwrapKey",
    "WrapKey",
    "Purge",
    "Encrypt",
    "Decrypt",
    "Sign",
    "Verify",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]
}

variable "encryption_key_type" {
  type        = string
  description = "Type of the encryption used for key"
  default     = "RSA"
}

variable "encryption_key_size" {
  type        = number
  description = "Size of the encryption key"
  default     = 2048
}

variable "encryption_key_options" {
  type        = list(string)
  description = "List of key options to assign to the Key Vault"
  default = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}
