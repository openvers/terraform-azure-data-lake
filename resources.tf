terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      configuration_aliases = [
        azurerm.auth_session,
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE KEY VAULT MODULE
##
## This module provisions an Azure Key Vault for encrypting data at rest.
##
## Parameters:
## - `resource_group_location`: Azure Resource Group location.
## - `resource_group_name`: Azure Resource Group name.
## - `key_vault_name`: Azure Key Vault name.
## ---------------------------------------------------------------------------------------------------------------------
module "azure_key_vault" {
  source = "./modules/azure_key_vault"

  resource_group_location = var.resource_group_location
  resource_group_name     = var.resource_group_name
  key_vault_name          = var.key_vault_name

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

data "azurerm_client_config" "current" {}

## ---------------------------------------------------------------------------------------------------------------------
## MEDALLION BRONZE BUCKET MODULE
##
## ADLS Bucket to Store Bronze Medallion Level/ Raw Data in Azure Data Lake.
##
## Parameters:
## - `resource_group_name`: Azure Resource Group name.
## - `resource_group_location`: Azure Resource Group location.
## - `security_group_id`: Microsoft Entra Security Group ID.
## - `bucket_name`: ADLS Bronze Bucket Name.
## - `container_name`: ADLS Bronze Bucket Container Name.
## - `key_vault_id`: The ID of the Key Vault to use for customer-managed encryption.
## ---------------------------------------------------------------------------------------------------------------------
module "bronze_bucket" {
  source = "./modules/adls_bucket"

  resource_group_name        = var.resource_group_name
  resource_group_location    = var.resource_group_location
  security_group_id          = var.security_group_id
  azure_storage_account_kind = var.azure_storage_account_kind
  bucket_name                = var.bronze_bucket_name
  container_name             = "${var.bronze_bucket_name}-container"
  key_vault_id               = module.azure_key_vault.key_vault_id
  key_name                   = module.azure_key_vault.key_name

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## MEDALLION SILVER BUCKET MODULE
##
## ADLS Bucket to Store Silver Medallion Level/ Processed Data in Azure Data Lake.
##
## Parameters:
## - `resource_group_name`: Azure Resource Group name.
## - `resource_group_location`: Azure Resource Group location.
## - `security_group_id`: Microsoft Entra Security Group ID.
## - `bucket_name`: ADLS Silver Bucket Name.
## - `container_name`: ADLS Silver Bucket Container Name.
## - `key_vault_id`: The ID of the Key Vault to use for customer-managed encryption.
## ---------------------------------------------------------------------------------------------------------------------
module "silver_bucket" {
  source = "./modules/adls_bucket"

  resource_group_name        = var.resource_group_name
  resource_group_location    = var.resource_group_location
  security_group_id          = var.security_group_id
  azure_storage_account_kind = var.azure_storage_account_kind
  bucket_name                = var.silver_bucket_name
  container_name             = "${var.silver_bucket_name}-container"
  key_vault_id               = module.azure_key_vault.key_vault_id
  key_name                   = module.azure_key_vault.key_name

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## MEDALLION GOLD BUCKET MODULE
##
## ADLS Bucket to Store Gold Medallion Level/ Processed Data in Azure Data Lake.
##
## Parameters:
## - `resource_group_name`: Azure Resource Group name.
## - `resource_group_location`: Azure Resource Group location.
## - `security_group_id`: Microsoft Entra Security Group ID.
## - `bucket_name`: ADLS Gold Bucket Name.
## - `container_name`: ADLS Gold Bucket Container Name.
## - `key_vault_id`: The ID of the Key Vault to use for customer-managed encryption.
## ---------------------------------------------------------------------------------------------------------------------
module "gold_bucket" {
  source = "./modules/adls_bucket"

  resource_group_name        = var.resource_group_name
  resource_group_location    = var.resource_group_location
  security_group_id          = var.security_group_id
  azure_storage_account_kind = var.azure_storage_account_kind
  bucket_name                = var.gold_bucket_name
  container_name             = "${var.gold_bucket_name}-container"
  key_vault_id               = module.azure_key_vault.key_vault_id
  key_name                   = module.azure_key_vault.key_name

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}
