# GitHub Actions Workflows Overview

This document provides a quick reference for the CI/CD workflows in this project.

## Workflow Chain

```
┌─────────────────────────────────────────────────────────┐
│  Feature Branch / PR                                    │
├─────────────────────────────────────────────────────────┤
│  1. Lint → 2. Test + 3. Security (parallel)           │
└─────────────────────────────────────────────────────────┘
                          ↓
                    Merge to main
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Main Branch                                            │
├─────────────────────────────────────────────────────────┤
│  1. Lint → 2. Test + 3. Security (parallel)           │
│            ↓                                            │
│  4. Build Docker Images (Dev) → Push to ACR            │
│            ↓                                            │
│  5. Deploy to Dev (automatic)                          │
│            ↓                                            │
│  5. Deploy to Prd (manual approval) ← Builds fresh     │
└─────────────────────────────────────────────────────────┘
```

## Workflows

### 1. Lint (`lint.yml`)
- **When**: Every push/PR
- **Does**: Runs pre-commit hooks (ruff, mypy, bandit, etc.)
- **Blocks**: Test and Security workflows

### 2. Test (`test.yml`)
- **When**: After Lint passes
- **Does**: Runs pytest for backend and frontend
- **Blocks**: Build workflow

### 3. Security (`security.yml`)
- **When**: After Lint passes, weekly schedule
- **Does**: Runs Trivy, Bandit, pip-audit
- **Blocks**: Build workflow

### 4. Build and Push Docker Images (`build.yml`)
- **When**: After Test + Security pass on main
- **Does**:
  - Builds backend and frontend images
  - Tags with commit SHA and `dev-latest`
  - Pushes to ACR in Dev environment
  - Scans images with Trivy
- **Environment**: Dev
- **Blocks**: Deploy workflow

### 5. Deploy Applications (`deploy.yml`)
- **When**: After Build passes, or manual
- **Jobs**:
  - **Deploy to Dev**: Automatic
    - Updates Container App Job with `dev-latest` image
    - Updates App Service with `dev-latest` image
  - **Build and Deploy to Prd**: Manual approval required
    - Builds fresh images from main
    - Tags with commit SHA and `prd-latest`
    - Updates Container App Job and App Service in Prd
- **Environments**: Dev (auto), Prd (manual approval)

## Image Tagging Strategy

| Environment | Tags | Usage |
|-------------|------|-------|
| Dev | `{sha}`, `dev-latest` | Automatic deployments use `dev-latest` |
| Prd | `{sha}`, `prd-latest` | Automatic deployments use `prd-latest` |

## Manual Triggers

All workflows support manual dispatch via:
- GitHub Actions UI: Actions → [Workflow] → Run workflow
- GitHub CLI: `gh workflow run [workflow-name].yml`

### Deploy to Specific Environment
```bash
gh workflow run deploy.yml -f environment=Dev
gh workflow run deploy.yml -f environment=Prd
```

### Deploy Specific Image Tag
```bash
gh workflow run deploy.yml -f environment=Dev -f image_tag=abc123
```

## Environment Protection

Configure in GitHub Settings → Environments:

### Dev
- No protection rules (automatic deployment)
- Secrets: ARM_*, AZURE_CREDENTIALS, AAD_*

### Prd
- ✅ Required reviewers (recommended)
- ✅ Restrict to main branch
- ⚠️ Wait timer (optional)
- Secrets: Same as Dev, but Prd-specific values

## Monitoring

- **Workflow Status**: GitHub Actions tab
- **Security Findings**: Security → Code scanning
- **Backend Job Logs**: `az containerapp job logs show`
- **Frontend Logs**: `az webapp log tail`

## Quick Commands

```bash
# Check workflow status
gh run list --workflow=deploy.yml

# View workflow logs
gh run view [run-id] --log

# List environments
gh api repos/:owner/:repo/environments

# Start backend job
az containerapp job start \
  --name caj-research-bandits-backend-dev \
  --resource-group rg-research-bandits-dev
```

## Troubleshooting

### Workflow not triggering
- Check if previous workflow passed
- Verify you're on main branch (for Build/Deploy)
- Check workflow_run event completed successfully

### Build/Deploy fails with auth error
- Verify environment secrets are configured
- Check service principal has correct permissions
- Ensure managed identities have ACR access

### Prd deployment not available
- Verify Dev deployment succeeded
- Check Prd environment is configured in GitHub
- Ensure you have required approver permissions

For detailed setup instructions, see [CICD_SETUP.md](./CICD_SETUP.md).
