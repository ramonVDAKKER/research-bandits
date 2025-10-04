#!/bin/bash

set -e

# Error handling
cleanup() {
  if [[ $? -ne 0 ]]; then
    echo "❌ Script failed. Check the error messages above."
    echo "💡 You may need to clean up partially created resources manually."
  fi
}
trap cleanup EXIT

# Check Azure CLI
check_prerequisites() {
  echo "Checking prerequisites..."

  if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed."
    exit 1
  fi

  if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Run 'az login'."
    exit 1
  fi

  echo "✓ Prerequisites met"
}

check_prerequisites

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

# Function to create storage account
create_storage_account() {
  local storage_account=$1
  local env_name=$2

  echo ""
  echo "=========================================="
  echo "Creating storage account: $storage_account ($env_name)"
  echo "=========================================="

  # Check if storage account already exists
  if az storage account show --name $storage_account --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "ℹ️  Storage account $storage_account already exists, skipping creation..."

    # Check if container exists
    if az storage container show --name $CONTAINER_NAME --account-name $storage_account --auth-mode login &>/dev/null; then
      echo "ℹ️  Container $CONTAINER_NAME already exists, skipping creation..."
    else
      echo "Creating missing container..."
      az storage container create \
        --name $CONTAINER_NAME \
        --account-name $storage_account \
        --auth-mode login
      echo "✓ Container '$CONTAINER_NAME' created"
    fi
    return
  fi

  # Create storage account
  az storage account create \
    --resource-group $RESOURCE_GROUP \
    --name $storage_account \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --public-network-access Enabled \
    --default-action Allow \
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

  # Allow Azure services to access
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

# Create resource group (check if exists first)
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
  az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --tags Project=research-bandits ManagedBy=Terraform
  echo "✓ Resource group created: $RESOURCE_GROUP"
else
  echo "ℹ️  Resource group $RESOURCE_GROUP already exists, skipping creation..."
fi

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
echo ""
echo "Done."
