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

data "azurerm_client_config" "this" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE KEY VAULT RESOURCE
##
## Create an Azure Key Vault.
## Parameters:
## - `name`: Key Vault name.
## - `resource_group_name`: Azure Resource Group name.
## - `location`: Azure Resource Group location.
## - `tenant_id`: Azure Tenant ID.
## - `sku_name`: Key Vault SKU name.
## - `soft_delete_enabled`: Flag to enable soft delete.
## - `enable_for_disk_encryption`: Flag to enable disk encryption.
## - `purge_protection_enabled`: Flag to enable purge protection.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault" "this" {
  provider = azurerm.auth_session

  name                        = replace(substr(var.key_vault_name, 0, 24), "/-$/", "")
  resource_group_name         = data.azurerm_resource_group.this.name
  location                    = data.azurerm_resource_group.this.location
  tenant_id                   = data.azurerm_client_config.this.tenant_id
  sku_name                    = var.sku_name
  enabled_for_disk_encryption = var.enable_for_disk_encryption
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE KEY VAULT ACCESS POLICY RESOURCE
##
## Configure Azure Key Vault Client Access Policies for
## custom storage encryption keys.
## Parameters:
##  - `key_vault_id`: Azure Key Vault ID.
##  - `tenant_id`: Azure Tenant ID.
##  - `object_id`: Azure Object ID.
##  - `secret_permissions`: List of secret permissions.
##  - `key_permissions`: List of key permissions.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "this" {
  provider = azurerm.auth_session

  key_vault_id       = azurerm_key_vault.this.id
  tenant_id          = data.azurerm_client_config.this.tenant_id
  object_id          = data.azurerm_client_config.this.object_id
  secret_permissions = var.secret_permissions
  key_permissions    = var.key_permissions
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE KEY VAULT KEY RESOURCE
##
## Create Key Vault Key for custom storage encryption.
## Parameters:
##  - `name`: Name of the key.
##  - `key_vault_id`: Azure Key Vault ID.
##  - `key_type`: Type of key.
##  - `key_size`: Size of key.
##  - `key_opts`: List of key options.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_key" "this" {
  provider = azurerm.auth_session
  depends_on = [
    azurerm_key_vault_access_policy.this,
  ]

  name         = "${var.key_vault_name}-sa-encryption-key"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = var.encryption_key_type
  key_size     = var.encryption_key_size
  key_opts     = var.encryption_key_options
}
