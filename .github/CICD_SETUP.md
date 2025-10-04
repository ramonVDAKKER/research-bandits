# CI/CD Pipeline Setup Guide

This guide explains the CI/CD pipelines for the research-bandits project and the required setup steps.

## Overview

The project uses GitHub Actions workflows with a strict dependency chain:

1. **1. Lint** - Code quality checks using pre-commit hooks
2. **2. Test** - Running pytest for both backend and frontend (depends on Lint)
3. **3. Security** - Vulnerability scanning with Trivy, Bandit, and pip-audit (depends on Lint)
4. **4. Build and Push Docker Images** - Building images and pushing to ACR Dev (depends on Test + Security, only on main branch)
5. **5. Deploy Applications** - Environment-based deployment:
   - **Dev**: Automatic deployment after successful build
   - **Prd**: Manual approval required, includes build + deploy in same job

## Architecture

- **Backend**: Deployed as an Azure Container App Job for on-demand execution
- **Frontend**: Deployed as an Azure App Service with Azure AD authentication
- **Images**: Stored in Azure Container Registry (ACR)



1. Create an Azure AD App Registration:
   ```bash
   az ad app create \
     --display-name "research-bandits-frontend-dev" \
     --sign-in-audience AzureADMyOrg \
     --web-redirect-uris "https://app-research-bandits-frontend-dev.azurewebsites.net/.auth/login/aad/callback"
   ```

2. Create a client secret:
   ```bash
   az ad app credential reset \
     --id <app-id> \
     --append
   ```

3. Configure API permissions (optional):
   - Microsoft Graph → User.Read

4. Save the following values:
   - Application (client) ID → `AAD_CLIENT_ID`
   - Directory (tenant) ID → `AAD_TENANT_ID`
   - Client secret value → `AAD_CLIENT_SECRET`

## Workflow Triggers and Dependencies

### 1. Lint (`lint.yml`)
- **Triggers**: Push to `main` or `feature/*`, PR to `main`, manual dispatch
- **Dependencies**: None (runs first)

### 2. Test (`test.yml`)
- **Triggers**: After Lint completes successfully, manual dispatch
- **Dependencies**: Requires Lint to pass

### 3. Security (`security.yml`)
- **Triggers**: After Lint completes successfully, scheduled weekly, manual dispatch
- **Dependencies**: Requires Lint to pass (except for scheduled runs)
- **Schedule**: Weekly on Monday at 9:00 AM UTC

### 4. Build and Push Docker Images (`build.yml`)
- **Triggers**: After both Test AND Security complete successfully on `main` branch, manual dispatch
- **Dependencies**: Requires both Test and Security to pass
- **Behavior**:
  - Builds images tagged with commit SHA and `dev-latest`
  - Pushes to ACR in Dev environment
  - Only runs on main branch (not on PRs or feature branches)

### 5. Deploy Applications (`deploy.yml`)
- **Triggers**: After Build completes successfully, manual dispatch
- **Dependencies**: Requires Build to pass
- **Environments**:
  - **Dev**: Automatic deployment using `dev-latest` images
  - **Prd**: Manual approval required, builds fresh `prd-latest` images then deploys
- **Manual Dispatch Parameters**:
  - `environment`: Dev or Prd (required)
  - `image_tag`: Override image tag (optional)
  - `backend_parameters`: JSON parameters for backend job (optional)

## Manual Job Execution

### Manually Deploy to an Environment

```bash
# Via GitHub Actions UI: Go to Actions → 5. Deploy Applications → Run workflow
# Select environment (Dev or Prd) and optionally specify image tag

# Or via GitHub CLI
gh workflow run deploy.yml \
  -f environment=Dev \
  -f image_tag=dev-latest
```

### Start Backend Job On-Demand

The backend Container App Job is not started automatically during deployment. To execute it:

```bash
# Via Azure CLI
az containerapp job start \
  --name caj-research-bandits-backend-dev \
  --resource-group rg-research-bandits-dev

# With environment variables
az containerapp job start \
  --name caj-research-bandits-backend-dev \
  --resource-group rg-research-bandits-dev \
  --env-vars "EXPERIMENT_ID=exp-001" "ITERATIONS=1000"
```

## Deployment Flow

```
Code Push/PR to feature branch
    ↓
[1. Lint] ← Runs first
    ↓
[2. Test] + [3. Security] ← Run in parallel after Lint passes
    ↓
Code Merge to main
    ↓
[1. Lint] ← Triggered on main
    ↓
[2. Test] + [3. Security] ← Run in parallel after Lint passes
    ↓
[4. Build Docker Images (Dev)] ← Only on main, after Test + Security pass
    ↓
[5. Deploy to Dev] ← Automatic, updates Container App Job and App Service
    ↓
[5. Build + Deploy to Prd] ← Manual approval required, builds fresh images
```

## Monitoring Deployments

### Backend Job
```bash
# List job executions
az containerapp job execution list \
  --name caj-research-bandits-backend-dev \
  --resource-group rg-research-bandits-dev \
  --output table

# Get logs
az containerapp job logs show \
  --name caj-research-bandits-backend-dev \
  --resource-group rg-research-bandits-dev
```

### Frontend App Service
```bash
# Get app status
az webapp show \
  --name app-research-bandits-frontend-dev \
  --resource-group rg-research-bandits-dev \
  --query state

# Stream logs
az webapp log tail \
  --name app-research-bandits-frontend-dev \
  --resource-group rg-research-bandits-dev
```

## Security Features

1. **Container Scanning**: Trivy scans all images for vulnerabilities
2. **Code Security**: Bandit scans Python code for security issues
3. **Dependency Scanning**: pip-audit checks for known vulnerabilities
4. **Secret Scanning**: detect-secrets prevents committing credentials
5. **Authentication**: Azure AD authentication on frontend
6. **RBAC**: Managed identities for ACR access
7. **HTTPS Only**: All endpoints enforce HTTPS

## Terraform State

The Terraform state is stored in Azure Storage. The state includes:
- Container Registry credentials
- Container Apps Environment
- App Service Plan
- Backend Container App Job
- Frontend App Service

The deployment workflows automatically read from this state to get resource names and configurations.

## First-Time Setup Checklist

### Prerequisites
- [ ] Azure subscription with appropriate permissions
- [ ] GitHub repository with Actions enabled
- [ ] Azure CLI installed locally

### Infrastructure Setup
- [ ] Create GitHub Actions service principal: See `.github/SETUP.md`
- [ ] Configure GitHub secrets (see Required GitHub Secrets section above)
- [ ] Create Azure AD App Registration for frontend (Dev and Prd)
- [ ] Update Terraform variables with AAD values in `.tfvars` files
- [ ] Deploy infrastructure: `make terraform-apply` (Dev first, then Prd)

### Pipeline Setup
- [ ] Push code to feature branch to trigger initial workflows (Lint → Test + Security)
- [ ] Merge to main to trigger Build workflow
- [ ] Verify Dev deployment completes automatically
- [ ] Verify backend Container App Job exists and is configured
- [ ] Verify frontend App Service is accessible
- [ ] Test Azure AD authentication on frontend
- [ ] Test manual backend job execution with parameters
- [ ] Configure GitHub environment protection rules for Prd (require approval)
- [ ] Manually trigger Prd deployment to test approval flow

### Image Tags
- **Dev**: Uses `dev-latest` tag for deployments, also tagged with commit SHA
- **Prd**: Uses `prd-latest` tag for deployments, also tagged with commit SHA
- **Specific versions**: Can override with manual dispatch using commit SHA

## Troubleshooting

### Build fails with ACR authentication error
- Verify `ARM_*` secrets are correctly configured
- Check that the GitHub Actions service principal has AcrPush role

### Frontend deployment succeeds but app doesn't start
- Check App Service logs: `az webapp log tail`
- Verify the image exists in ACR
- Check that managed identity has AcrPull permission

### Azure AD authentication fails
- Verify redirect URI matches exactly in Azure AD
- Check `AAD_CLIENT_SECRET` is correctly set
- Ensure AAD app has correct permissions

### Backend job won't start
- Check Container Apps Environment is running
- Verify managed identity has AcrPull permission
- Check job configuration: `az containerapp job show`

## Production Environment

Production deployment is already configured in `infra/environments/prd/`.

### Key Differences from Dev:
- **ACR SKU**: Standard (vs Basic in Dev)
- **App Service Plan**: P1v2 (vs F1 Free in Dev)
- **Backend Resources**: 1 CPU / 2GB RAM (vs 0.5 CPU / 1GB in Dev)
- **Log Retention**: 90 days (vs 30 days in Dev)
- **Always On**: Enabled for frontend (vs Disabled in Dev)
- **Image Tags**: Uses `prd-latest` (separate from Dev's `dev-latest`)

### Deployment Process:
1. Dev deployment must succeed first
2. Manual approval required in GitHub Actions (configure in Settings → Environments → Prd)
3. Fresh images are built from main branch for production
4. Images are tagged with both commit SHA and `prd-latest`

### Recommended GitHub Environment Protection:
- Navigate to Settings → Environments → Prd
- Enable "Required reviewers" (add team members)
- Enable "Wait timer" (optional, e.g., 5 minutes)
- Restrict to main branch only
