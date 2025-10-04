#!/usr/bin/env bash

# Script to create Azure AD App Registrations for frontend authentication
# Usage: ./create-aad-app-registration.sh <environment>
# Example: ./create-aad-app-registration.sh dev

set -euo pipefail

ENVIRONMENT="${1:-}"

if [[ -z "$ENVIRONMENT" ]]; then
  echo "❌ Error: Environment not specified"
  echo "Usage: $0 <environment>"
  echo "Example: $0 dev"
  exit 1
fi

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prd" ]]; then
  echo "❌ Error: Environment must be 'dev' or 'prd'"
  exit 1
fi

echo "🔐 Creating Azure AD App Registration for $ENVIRONMENT environment..."
echo ""

# Configuration
APP_NAME="research-bandits-frontend-$ENVIRONMENT"
REDIRECT_URI="https://app-research-bandits-frontend-$ENVIRONMENT.azurewebsites.net/.auth/login/aad/callback"

echo "📋 Configuration:"
echo "  App Name: $APP_NAME"
echo "  Redirect URI: $REDIRECT_URI"
echo ""

# Check if app already exists
EXISTING_APP=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_APP" ]]; then
  echo "⚠️  App registration '$APP_NAME' already exists (App ID: $EXISTING_APP)"
  read -p "Do you want to create a new client secret for this app? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  APP_ID="$EXISTING_APP"
else
  echo "🔨 Creating new app registration..."
  az ad app create \
    --display-name "$APP_NAME" \
    --sign-in-audience AzureADMyOrg \
    --web-redirect-uris "$REDIRECT_URI" \
    > /dev/null

  APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
  echo "✅ App registration created: $APP_ID"
fi

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "🔑 Creating client secret..."
SECRET_OUTPUT=$(az ad app credential reset --id "$APP_ID" --append --query '{appId:appId,password:password,tenant:tenant}' -o json)

CLIENT_SECRET=$(echo "$SECRET_OUTPUT" | jq -r '.password')

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ Azure AD App Registration created successfully!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Add these secrets to GitHub Environment: $ENVIRONMENT"
echo "(Settings → Environments → $ENVIRONMENT → Environment secrets)"
echo ""
echo "Secret Name: AAD_CLIENT_ID"
echo "Value: $APP_ID"
echo ""
echo "Secret Name: AAD_TENANT_ID"
echo "Value: $TENANT_ID"
echo ""
echo "Secret Name: AAD_CLIENT_SECRET"
echo "Value: $CLIENT_SECRET"
echo ""
echo "⚠️  IMPORTANT: Save the CLIENT_SECRET value now!"
echo "   You won't be able to retrieve it again."
echo ""
echo "═══════════════════════════════════════════════════════════════"
