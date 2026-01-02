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
## AZURE STORAGE ACCOUNT RESOURCE
##
## Create an ADLS Bucket.
##
## Parameters:
## - `name`: ADLS bucket name.
## - `resource_group_name`: Azure Resource Group name.
## - `location`: Azure Resource Group location.
## - `account_tier`: ADLS account tier.
## - `account_replication_type`: ADLS replication type.
## - `is_hns_enabled`: Flag to enable hierarchical namespace feature.
## - `key_vault_key_id`: The ID of the Key Vault key to use for customer-managed encryption.
## - `user_assigned_identity_id`: The ID of the User Assigned Managed Identity to use
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "this" {
  provider = azurerm.auth_session

  name                     = replace(substr(var.bucket_name, 0, 24), "/-/", "")
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_kind             = var.azure_storage_account_kind
  account_tier             = "Premium"
  account_replication_type = "LRS"
  is_hns_enabled           = var.hierarchical_namespace

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURERM ROLE ASSIGNMENT RESOURCE
##
## Assign the Storage Account Assigned Managed Identity the
## Key Vault Crypto Service Encryption User Role to provide access
## to Azure Key Vault to manage Custom Encryption Keys.
##
## https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-configure-existing-account?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&tabs=azure-portal#use-a-system-assigned-managed-identity-to-authorize-access
##
## Parameters:
## - `scope`: ADLS bucket ID.
## - `role_definition_name`: Azure AD role name.
## - `principal_id`: Azure AD security group.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  provider = azurerm.auth_session

  scope                            = azurerm_storage_account.this.id
  role_definition_name             = "Key Vault Crypto Service Encryption User"
  principal_id                     = azurerm_storage_account.this.identity[0].principal_id
  skip_service_principal_aad_check = true
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE STORAGE CONTAINER RESOURCE
##
## Create an Container in the ADLS Storage Account.
##
## Parameters:
## - `name`: Name of the container.
## - `storage_account_name`: Name of the storage account.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "this" {
  provider = azurerm.auth_session

  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURERM KEY VAULT ACCESS POLICY RESOURCE
##
## Create an Access Policy in the Key Vault.
##
## Parameters:
## - `key_vault_id`: ID of the Key Vault.
## - `tenant_id`: Tenant ID of the Key Vault.
## - `object_id`: Application ID of the Storage Account System Assigned Managed Identity.
## - `secret_permissions`: List of secret permissions.
## - `key_permissions`: List of key permissions.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "this" {
  provider = azurerm.auth_session

  key_vault_id       = var.key_vault_id
  tenant_id          = data.azurerm_client_config.this.tenant_id
  object_id          = azurerm_storage_account.this.identity[0].principal_id
  secret_permissions = var.secret_permissions
  key_permissions    = var.key_permissions
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE STORAGE ACCOUNT CUSTOMER MANAGED KEY RESOURCE
##
## Create an Customer Managed Key in the ADLS Storage Account.
##
## Parameters:
## - `storage_account_name`: Name of the storage account.
## - `key_vault_id`: ID of the Key Vault.
## - `key_name`: Name of the key.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account_customer_managed_key" "provider" {
  provider = azurerm.auth_session
  depends_on = [
    azurerm_role_assignment.this,
    azurerm_key_vault_access_policy.this,
  ]

  storage_account_id = azurerm_storage_account.this.id
  key_vault_id       = var.key_vault_id
  key_name           = var.key_name
}
