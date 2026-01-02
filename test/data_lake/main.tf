terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-azure-workspace"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  suffix = "test-${random_string.this.result}"
}

provider "azurerm" {
  features {}
}

##---------------------------------------------------------------------------------------------------------------------
## AZURERM PROVIDER
##
## Azure Resource Manager (Azurerm) provider authenticated with service account client credentials.
##
## Parameters:
## - `client_id`: Service account client ID.
## - `client_secret`: Service account client secret.
## - `subscription_id`: Azure subscription ID.
## - `tenant_id`: Azure tenant ID.
## - `prevent_deletion_if_contains_resources`: Disable resource loss prevention mechanism.
##---------------------------------------------------------------------------------------------------------------------
provider "azurerm" {
  alias = "auth_session"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_deleted_keys_on_destroy = true
    }
  }
}

##---------------------------------------------------------------------------------------------------------------------
## AZURERM RESOURCE GROUP RESOURCE
##
## Create an Azure Resource Group to organize/group collections of resources, and isolate for billing.
##
## Parameters:
## - `name`: Azure Resource Group name.
## - `location`: Azure resource group location.
##---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  provider = azurerm.auth_session

  name     = "${local.suffix}-resource-group"
  location = var.azure_region
}

## ---------------------------------------------------------------------------------------------------------------------
## DATA LAKE MODULE
##
## Provisions a complete Azure Data Lake environment, including Blob Storage containers for bronze, silver, and gold medallion data layers,
## IAM roles and policies, encryption, function integration, and supporting resources.
##
## Parameters:
## - `bronze_bucket_name`: Name of the ADLS Storage container for raw/bronze data.
## - `silver_bucket_name`: Name of the ADLS Storage container for processed/silver data.
## - `gold_bucket_name`: Name of the ADLS Storage container for curated/gold data.
##
## Notes:
## - This module is designed for end-to-end data lake testing and development.
## - Additional configuration may be required for Azure Function integration and IAM roles depending on your use case.
## ---------------------------------------------------------------------------------------------------------------------
module "data_lake" {
  source = "../../"

  azure_storage_account_kind = "BlockBlobStorage"
  bronze_bucket_name         = "${local.suffix}-bronze"
  silver_bucket_name         = "${local.suffix}-silver"
  gold_bucket_name           = "${local.suffix}-gold"
  key_vault_name             = "${replace(local.suffix, " ", "-")}-datalake-akv"
  security_group_id          = var.SECURITY_GROUP_ID
  resource_group_name        = azurerm_resource_group.this.name
  resource_group_location    = azurerm_resource_group.this.location

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURERM STORAGE MANAGEMENT POLICY RESOURCE
##
## This resource defines a management policy for the Azure Storage account to manage blob lifecycle.
##
## Parameters:
## - `storage_account_id`: The ID of the Azure Storage account to which the management policy applies.
## - `rule`: A block defining the lifecycle management rules for blobs in the storage account.
##   - `name`: The name of the rule.
##   - `enabled`: Whether the rule is enabled.
##   - `filters`: A block defining filters for the rule.
##   - `actions`: A block defining actions to take on blobs that match the rule.
resource "azurerm_storage_management_policy" "this" {
  provider           = azurerm.auth_session
  storage_account_id = module.data_lake.bronze_bucket_id

  rule {
    name    = "${local.suffix}-bronze-lifecycle-rule"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["test/*"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 30
      }
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## LOCAL FILE RESOURCE FOR S3 TESTING
##
## Generates a sample file at build time for testing S3 uploads to the bronze bucket.
## The file includes a timestamp and test metadata.
##
## Parameters:
## - `content`: The contents of the sample file (includes timestamp).
## - `filename`: The path where the file will be created locally.
## ---------------------------------------------------------------------------------------------------------------------
resource "local_file" "bronze_sample" {
  content  = <<-EOT
This is a sample file for testing S3 upload to the bronze bucket via Terraform.
Uploaded by: Terraform test
Date: ${timestamp()}
EOT
  filename = "${path.module}/sample_bronze_upload.txt"
}

## ---------------------------------------------------------------------------------------------------------------------
## ADLS OBJECT RESOURCE FOR TESTING
##
## Uploads the generated sample file to the bronze ADLS container for testing purposes.
##
## Parameters:
## - `name`: The name of the blob in the storage container.
## - `storage_account_name`: The name of the Azure Storage account.
## - `storage_container_name`: The name of the Azure Storage container.
## - `type`: The type of the blob (Block Blob).
## - `source`: The local file to upload.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_blob" "bronze_test_upload" {
  provider = azurerm.auth_session

  name                   = "test/sample_bronze_upload.txt"
  storage_account_name   = module.data_lake.bronze_bucket_name
  storage_container_name = module.data_lake.bronze_bucket_container_name
  type                   = "Block"
  source                 = local_file.bronze_sample.filename
}
