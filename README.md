<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Microsoft_Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/openvers/terraform-azure-data-lake/tf-integration-test.yml?style=flat&logo=github&label=CD%20(September%202024)" height="25px"/>
</p>

# Terraform Azure Data Lake Module

## Overview

This repository provides a modular, production-ready Terraform implementation for provisioning a secure, scalable Azure Data Lake. It includes:
- Medallion architecture ADLS containers (Bronze, Silver, Gold)
- Azure Key Vault Customer Managed encryption
- IAM roles and policies
- Secure access patterns and lifecycle management

The modules are designed for flexibility and can be used for both development and production environments.

## Module Structure

- `modules/azure_key_vault/` – Customer Managed encryption key for ADLS Containers
- `modules/adls_bucket/` – ADLS container creation, versioning, encryption, access (lifecycle configured as part of test harness)

---

## Usage

```hcl
module "data_lake" {
  source = "../../"

  azure_storage_account_kind = "BlockBlobStorage"
  bronze_bucket_name         = "my-bronze-bucket"
  silver_bucket_name         = "my-silver-bucket"
  gold_bucket_name           = "my-gold-bucket"

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}
```

## Testing

A test harness is provided in the `test/` directory. It includes:
- Service account and OIDC federation setup
- Automated creation of a sample file and upload to the bronze bucket using Terraform's `local_file` and `azure_storage_blob` resources
- Output variables for integration with CI/CD pipelines

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

## Prerequisites

Before running Terraform with certificate-based authentication, create a client certificate and assign the public certificate to a pre-created Azure service account application.

```bash
# Create a private key and self-signed certificate for the pre-created Azure application.
mkdir -p ~/creds/azure
export ARM_CLIENT_CERTIFICATE_PASSWORD=$(openssl rand -base64 32)

openssl req -x509 -newkey rsa:4096 \
  -keyout ~/creds/azure/service-account.key \
  -out ~/creds/azure/service-account.crt \
  -days 365 \
  -nodes \
  -subj "/CN=terraform-azure-service-account"

# Package the certificate and private key as a PKCS#12 bundle for Terraform authentication.
openssl pkcs12 -export \
  -out ~/creds/azure/service-account.pfx \
  -inkey ~/creds/azure/service-account.key \
  -in ~/creds/azure/service-account.crt \
  -passout "pass:$ARM_CLIENT_CERTIFICATE_PASSWORD"

# Upload the public certificate to the pre-created Azure AD application/service account.
# Replace <application-client-id> with the Application (client) ID of the existing app registration.
az ad app credential reset \
  --id "<application-client-id>" \
  --cert "@~/creds/azure/service-account.crt" \
  --append

# Azure CLI certificate login requires a PEM file containing the private key and certificate.
cat ~/creds/azure/service-account.key ~/creds/azure/service-account.crt > ~/creds/azure/service-account.pem

export WORKING_DIR=$(pwd)
cat << 'EOF' | envsubst '$WORKING_DIR $ARM_CLIENT_CERTIFICATE_PASSWORD' > ~/creds/azure.secrets.envrc
export TF_VAR_SECURITY_GROUP_ID=$(terraform -chdir=$WORKING_DIR/test/service_account output -raw security_group_id 2>/dev/null || true)
export AZURE_CLIENT_ID=$(terraform -chdir=$WORKING_DIR/test/service_account output -raw service_account_client_id 2>/dev/null || true)
export AZURE_CLIENT_SECRET=$(terraform -chdir=$WORKING_DIR/test/service_account output -raw service_account_client_secret 2>/dev/null || true)

if [ -z "$AZURE_CLIENT_ID" ] || [ -z "$AZURE_CLIENT_SECRET" ]; then
  export ARM_CLIENT_ID="<application-client-id>"
  export ARM_CLIENT_CERTIFICATE_PATH="$HOME/creds/azure/service-account.pfx"
  export ARM_CLIENT_CERTIFICATE_PASSWORD="$ARM_CLIENT_CERTIFICATE_PASSWORD"

  export AZURE_CLIENT_ID=$ARM_CLIENT_ID
  export AZURE_CLIENT_CERTIFICATE_PATH=$ARM_CLIENT_CERTIFICATE_PATH
  export AZURE_CLIENT_CERTIFICATE_PASSWORD=$ARM_CLIENT_CERTIFICATE_PASSWORD
else
  export ARM_CLIENT_ID="$AZURE_CLIENT_ID"
  export ARM_CLIENT_CERTIFICATE_PATH=""
  export ARM_CLIENT_CERTIFICATE_PASSWORD=""

  export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
  export AZURE_CLIENT_CERTIFICATE_PATH=$ARM_CLIENT_CERTIFICATE_PATH
  export AZURE_CLIENT_CERTIFICATE_PASSWORD=$ARM_CLIENT_CERTIFICATE_PASSWORD
fi

export TF_API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')
EOF
```

### Local Deployment Testing

```bash
az login \
  --service-principal \
  --username "$ARM_CLIENT_ID" \
  --certificate ~/creds/azure/service-account.pem \
  --tenant "$ARM_TENANT_ID"
terraform login app.terraform.io

terraform -chdir=test/service_account init
terraform -chdir=test/service_account plan
terraform -chdir=test/service_account apply -auto-approve

direnv reload
terraform -chdir=test/data_lake init
terraform -chdir=test/data_lake plan
terraform -chdir=test/data_lake apply -auto-approve

export BRONZE_BUCKET_NAME=$(terraform -chdir=test/data_lake output -raw bronze_bucket_name)
export BRONZE_BUCKET_CONTAINER_NAME=$(terraform -chdir=test/data_lake output -raw bronze_bucket_container_name)
export SILVER_BUCKET_NAME=$(terraform -chdir=test/data_lake output -raw silver_bucket_name)
export SILVER_BUCKET_CONTAINER_NAME=$(terraform -chdir=test/data_lake output -raw silver_bucket_container_name)
export GOLD_BUCKET_NAME=$(terraform -chdir=test/data_lake output -raw gold_bucket_name)
export GOLD_BUCKET_CONTAINER_NAME=$(terraform -chdir=test/data_lake output -raw gold_bucket_container_name)

pytest -m "client_credentials"

terraform -chdir=test/data_lake destroy -auto-approve
terraform -chdir=test/service_account destroy -auto-approve
```

### Manual Dispatch Testing

```bash
# Try the Terraform Read job first
act -j terraform-dispatch-plan \
  -e .github/local.json \
  -s AZURE_CLIENT_ID \
  -s AZURE_CLIENT_CERTIFICATE_PATH=/creds/azure/service-account.pfx \
  -s AZURE_CLIENT_CERTIFICATE_PASSWORD \
  -s AZURE_SUBSCRIPTION_ID \
  -s AZURE_TENANT_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --container-options "-v $HOME/creds/azure:/creds/azure:ro"

act -j terraform-dispatch-apply \
  -e .github/local.json \
  -s AZURE_CLIENT_ID \
  -s AZURE_CLIENT_CERTIFICATE_PATH=/creds/azure/service-account.pfx \
  -s AZURE_CLIENT_CERTIFICATE_PASSWORD \
  -s AZURE_SUBSCRIPTION_ID \
  -s AZURE_TENANT_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --container-options "-v $HOME/creds/azure:/creds/azure:ro"

act -j terraform-dispatch-destroy \
  -e .github/local.json \
  -s AZURE_CLIENT_ID \
  -s AZURE_CLIENT_CERTIFICATE_PATH=/creds/azure/service-account.pfx \
  -s AZURE_CLIENT_CERTIFICATE_PASSWORD \
  -s AZURE_SUBSCRIPTION_ID \
  -s AZURE_TENANT_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --container-options "-v $HOME/creds/azure:/creds/azure:ro"
```

### Integration Testing

```bash
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-destroy \
  -e .github/local.json \
  -s AZURE_CLIENT_ID \
  -s AZURE_CLIENT_CERTIFICATE_PATH=/creds/azure/service-account.pfx \
  -s AZURE_CLIENT_CERTIFICATE_PASSWORD \
  -s AZURE_SUBSCRIPTION_ID \
  -s AZURE_TENANT_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --container-options "-v $HOME/creds/azure:/creds/azure:ro" \
  --artifact-server-path /tmp/artifacts
```

### Unit Testing

```bash
act -j terraform-unit-tests \
  -e .github/local.json \
  -s AZURE_CLIENT_ID \
  -s AZURE_CLIENT_CERTIFICATE_PATH=/creds/azure/service-account.pfx \
  -s AZURE_CLIENT_CERTIFICATE_PASSWORD \
  -s AZURE_SUBSCRIPTION_ID \
  -s AZURE_TENANT_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --container-options "-v $HOME/creds/azure:/creds/azure:ro"
```

---

## License

See [LICENSE](./LICENSE) for details.