""" Unit Test: Azure Blob Write

Unit testing Azure Blob Write involves verifying the write access to
our Azure Data Lake Storage (ADLS) buckets.

References:
 - https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers
 - https://learn.microsoft.com/en-ca/entra/identity-platform/v2-oauth2-client-creds-grant-flow?wt.mc_id=SEC-MVP-5004985#third-case-access-token-request-with-a-federated-credential
 - https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity.clientassertioncredential?view=azure-python
 - https://learn.microsoft.com/en-us/graph/api/application-post-federatedidentitycredentials?view=graph-rest-1.0&tabs=python

Local Testing Steps:
```
terraform init && \
terraform apply -auto-approve

export BRONZE_BUCKET_NAME=$(terraform output -raw bronze_bucket_name)
export SILVER_BUCKET_NAME=$(terraform output -raw silver_bucket_name)
export GOLD_BUCKET_NAME=$(terraform output -raw gold_bucket_name)

python3 -m pytest -m github

terraform destroy -auto-approve
```
"""

from azure.identity import ClientAssertionCredential

import asyncio
import requests
import logging
import base64
import pytest
import adlfs
import json
import uuid
import time
import os

# Environment Variables
BRONZE_BUCKET=os.getenv('BRONZE_BUCKET_NAME')
BRONZE_CONTAINER=os.getenv('BRONZE_BUCKET_CONTAINER_NAME')
SILVER_BUCKET=os.getenv('SILVER_BUCKET_NAME')
SILVER_CONTAINER=os.getenv('SILVER_BUCKET_CONTAINER_NAME')
GOLD_BUCKET=os.getenv('GOLD_BUCKET_NAME')
GOLD_CONTAINER=os.getenv('GOLD_BUCKET_CONTAINER_NAME')
assert not BRONZE_BUCKET is None
assert not BRONZE_CONTAINER is None
assert not SILVER_BUCKET is None
assert not SILVER_CONTAINER is None
assert not GOLD_BUCKET is None
assert not GOLD_CONTAINER is None

def client_assertion():
    OIDC_TOKEN=os.getenv('OIDC_TOKEN')
    assert not OIDC_TOKEN is None

    return OIDC_TOKEN

def exchange_oidc_token():
    AZURE_CLIENT_ID=os.getenv('AZURE_CLIENT_ID')
    AZURE_TENANT_ID=os.getenv('AZURE_TENANT_ID')
    assert not AZURE_CLIENT_ID is None
    assert not AZURE_TENANT_ID is None

    return ClientAssertionCredential(
        client_id=AZURE_CLIENT_ID,
        tenant_id=AZURE_TENANT_ID,
        func=client_assertion,
   )


def _write_blob(fs, sa_container, payload):
    with fs.open(f'{sa_container}/test.json', 'w') as f:
        f.write(json.dumps(payload))

def _read_blob(fs, sa_container):
    with fs.open(f'{sa_container}/test.json', 'rb') as f:
        return json.loads(f.read())

async def _verify_blob_write(sa_bucket, sa_container, payload, **filesystem_kwargs):
    fs = adlfs.AzureBlobFileSystem(
        account_name=sa_bucket,
        **filesystem_kwargs
    )

    await asyncio.to_thread(_write_blob, fs, sa_container, payload)
    await asyncio.sleep(120)
    rs = await asyncio.to_thread(_read_blob, fs, sa_container)

    assert rs['test_value'] == payload['test_value']

async def _verify_medallion_blob_writes(payload, **filesystem_kwargs):
    await asyncio.gather(*(
        _verify_blob_write(sa_bucket, sa_container, payload, **filesystem_kwargs)
        for sa_bucket, sa_container in [
            (BRONZE_BUCKET, BRONZE_CONTAINER), 
            (SILVER_BUCKET, SILVER_CONTAINER), 
            (GOLD_BUCKET, GOLD_CONTAINER)]
    ))

@pytest.mark.github
@pytest.mark.client_credentials
def test_azure_credentials_blob_write(payload=None):
    logging.info('Pytest | Test Azure Blob Write')
    payload = payload or {'test_value': str(uuid.uuid4())}
    AZURE_CLIENT_ID=os.getenv('AZURE_CLIENT_ID')
    AZURE_CLIENT_SECRET=os.getenv('AZURE_CLIENT_SECRET')
    AZURE_TENANT_ID=os.getenv('AZURE_TENANT_ID')
    assert not AZURE_CLIENT_ID is None
    assert not AZURE_CLIENT_SECRET is None
    assert not AZURE_TENANT_ID is None

    asyncio.run(_verify_medallion_blob_writes(
        payload,
        client_id=AZURE_CLIENT_ID,
        client_secret=AZURE_CLIENT_SECRET,
        tenant_id=AZURE_TENANT_ID
    ))

@pytest.mark.github
@pytest.mark.oidc
def test_azure_oidc_blob_trigger(payload=None):
    logging.info('Pytest | Test Azure Blob Write')
    payload = payload or {'test_value': str(uuid.uuid4())}
    creds = exchange_oidc_token()

    asyncio.run(_verify_medallion_blob_writes(
        payload,
        credential=creds
    ))
