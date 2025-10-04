#!/bin/bash

set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env file in script directory
if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "Loading variables from .env file..."
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Variables (can be overridden by environment variables)
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-terraform-state}"
STORAGE_ACCOUNT_DEV="${STORAGE_ACCOUNT_DEV:-sttfstatebanditsdev}"
STORAGE_ACCOUNT_PRD="${STORAGE_ACCOUNT_PRD:-sttfstatebanditsprd}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"
LOCATION="${LOCATION:-westeurope}"
ALLOWED_IPS="${ALLOWED_IPS:-}"  # Comma-separated list of IP addresses/CIDR ranges

# Function to create storage account with security settings
create_storage_account() {
  local storage_account=$1
  local env_name=$2

  echo ""
  echo "=========================================="
  echo "Creating storage account: $storage_account ($env_name)"
  echo "=========================================="

  # Create storage account with security settings
  az storage account create \
    --resource-group $RESOURCE_GROUP \
    --name $storage_account \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --public-network-access Enabled \
    --default-action Deny \
    --tags Project=research-bandits Environment=$env_name ManagedBy=Terraform

  echo "✓ Storage account created with secure defaults"

  # Enable versioning and soft delete for blob data protection
  az storage account blob-service-properties update \
    --account-name $storage_account \
    --resource-group $RESOURCE_GROUP \
    --enable-versioning true \
    --enable-delete-retention true \
    --delete-retention-days 30 \
    --enable-container-delete-retention true \
    --container-delete-retention-days 30

  echo "✓ Enabled blob versioning and soft delete (30 days retention)"

  # Add IP restrictions if provided
  if [ -n "$ALLOWED_IPS" ]; then
    echo "Adding IP restrictions..."
    IFS=',' read -ra IP_ARRAY <<< "$ALLOWED_IPS"
    for ip in "${IP_ARRAY[@]}"; do
      ip=$(echo $ip | xargs)  # Trim whitespace
      echo "  Adding IP: $ip"
      az storage account network-rule add \
        --resource-group $RESOURCE_GROUP \
        --account-name $storage_account \
        --ip-address $ip
    done
    echo "✓ IP restrictions applied"
  else
    echo "⚠ WARNING: No IP restrictions configured. Storage account denies all access by default."
  fi

  # Allow Azure services to access (required for some Azure services)
  az storage account update \
    --resource-group $RESOURCE_GROUP \
    --name $storage_account \
    --bypass AzureServices

  echo "✓ Enabled Azure Services bypass"

  # Wait for network rules to propagate
  echo "Waiting for network rules to propagate (60 seconds)..."
  sleep 60

  # Create blob container
  az storage container create \
    --name $CONTAINER_NAME \
    --account-name $storage_account \
    --auth-mode login

  echo "✓ Container '$CONTAINER_NAME' created"
}

echo "Creating Terraform backend infrastructure..."
echo ""

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Project=research-bandits ManagedBy=Terraform

echo "✓ Resource group created: $RESOURCE_GROUP"

# Create both storage accounts
create_storage_account $STORAGE_ACCOUNT_DEV "dev"
create_storage_account $STORAGE_ACCOUNT_PRD "prd"

echo ""
echo "=========================================="
echo "✓ Backend infrastructure created successfully!"
echo "=========================================="
echo ""
echo "Storage accounts created:"
echo "  - $STORAGE_ACCOUNT_DEV (dev)"
echo "  - $STORAGE_ACCOUNT_PRD (prd)"
echo ""
echo "Security features enabled:"
echo "  - HTTPS only with TLS 1.2+"
echo "  - Public blob access disabled"
echo "  - Network access: deny by default"
echo "  - Blob versioning enabled"
echo "  - Soft delete: 30 days retention"
echo "  - Azure Services bypass enabled"
echo "  - Common tags applied"
echo ""
if [ -z "$ALLOWED_IPS" ]; then
  echo "⚠ IMPORTANT: Add ALLOWED_IPS to .env file or set as environment variable"
  echo "  to allow access to the storage accounts!"
  echo ""
fi
echo "Done."
