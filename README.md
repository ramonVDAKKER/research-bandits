# Research-bandits

This repository support own research projects on contextual bandits.

Paper:
- [Valid Post-Contextual Bandit Inference](https://arxiv.org/abs/2505.13897)

## 1. Features

TODO

## 2. Prerequisites

### General
- Linux/WSL2
- Docker
- **Python 3.13+**
- **[uv](https://github.com/astral-sh/uv)** (v0.8.13+) - fast Python package manager
- **Git**
- **pre-commit** - automated code quality checks

### Infrastructure (Only needed for deployment on Azure)
- **Azure CLI** - For Azure authentication (`az login`)
- **Terraform >= 1.0** - Infrastructure as code

## 2. Getting Started

### 1. Install the Package

```bash
# Install in development mode
uv pip install -e .
```

### 2. Set Up Pre-commit Hooks

This project uses pre-commit to enforce code quality standards automatically.

```bash
# Install pre-commit hooks
pre-commit install

# Run all checks manually
make lint
```

#### Pre-commit Checks

The following checks run automatically on every commit:

**Code Quality:**
- `ruff` - Fast Python linter and formatter (line length: 120)
- `isort` - Import sorting (black profile)
- `mypy` - Static type checking

**Security:**
- `bandit` - Python security linting
- `detect-secrets` - Secret scanning (prevents committing credentials)

**Style & Documentation:**
- `pydocstyle` - Docstring style checking
- `interrogate` - Docstring coverage (minimum 80%)

**General:**
- YAML validation
- Trailing whitespace removal
- End-of-file fixing
- Large file detection

#### Updating the Secrets Baseline

If you add legitimate secrets to `.env.example` or test files:

```bash
# Update the baseline to include new known secrets
detect-secrets scan --baseline .secrets.baseline

# Or let pre-commit install it first
pre-commit run detect-secrets --all-files
```

## 3. Infrastructure (deployment to Azure)

This project uses Terraform to manage Azure infrastructure with separate dev and prd environments within the same Azure subscription.

### Terraform Backend Setup

The Terraform state is stored in Azure Storage with the following structure:

```
infra/
├── environments/
│   ├── dev/          # Development environment
│   └── prd/          # Production environment
├── modules/          # Shared Terraform modules
└── scripts/          # Infrastructure automation scripts
```

#### Initial Backend Setup

1. Configure environment variables in `infra/scripts/.env`:
   ```bash
   cp infra/scripts/.env.example infra/scripts/.env
   # Edit .env with your values
   ```

2. Create the backend infrastructure:
   ```bash
   make terraform-init-backend
   ```

   This creates:
   - Resource group: `rg-terraform-state`
   - Storage accounts: `sttfstatebanditsdev`, `sttfstatebanditsprd`
   - Blob containers with tfstate files

#### Security Features

The storage accounts are configured with:
- **HTTPS only** with TLS 1.2+
- **IP restrictions** (configured via `.env`)
- **Network default deny** with allowlist
- **Blob versioning** enabled
- **Soft delete** (30 days retention)
- **Public blob access** disabled
- **Azure Services bypass** enabled

#### Working with Terraform

**Local Development (Dev Environment):**

Use Makefile commands for the dev environment:

```bash
# Initialize Terraform for dev
make terraform-init

# Plan infrastructure changes
make terraform-plan

# Apply infrastructure changes
make terraform-apply

# Destroy all dev infrastructure (with confirmation prompt)
make terraform-destroy
```

**Note:** Production (prd) infrastructure is managed via CI/CD pipelines only.

**⚠️ Destroying Infrastructure:**

The `terraform-destroy` command will:
- Prompt for confirmation before destroying resources
- Only destroy resources managed by Terraform in the dev environment
- NOT delete the backend storage accounts (state files remain intact)

To completely remove all infrastructure including backend storage:
```bash
# 1. Destroy dev resources
make terraform-destroy

# 2. Manually delete the resource group containing state storage
az group delete --name rg-terraform-state --yes
```

#### Environment Variables

**For local development:**

Use Azure CLI authentication (recommended):
```bash
az login
```

The Makefile automatically exports `ARM_SUBSCRIPTION_ID` from your Azure CLI session.

**For CI/CD pipelines:**

Set these as secrets:
```bash
ARM_SUBSCRIPTION_ID=your-subscription-id
ARM_TENANT_ID=your-tenant-id
ARM_CLIENT_ID=your-client-id        # Service principal
ARM_CLIENT_SECRET=your-client-secret # Service principal
```

#### Common Tags

All Azure resources are tagged with:
- `Project`: research-bandits
- `Environment`: dev/prd
- `ManagedBy`: Terraform

### CI/CD Pipeline

Infrastructure deployments to production are managed via GitHub Actions with automated dev deployments and manual production approvals.

#### Pipeline Flow

```
PR → main → Dev (auto) → Prd (manual approval required)
```

**Workflow:**
1. **Pull Request**: Terraform plan runs and comments on PR (read-only, no secrets)
2. **Merge to main**: Automatically deploys to dev environment
3. **Production**: Requires manual approval before deploying to prd

#### Setup GitHub Actions

Complete setup guide: [`.github/SETUP.md`](.github/SETUP.md)

**Quick setup:**
1. Create Azure Service Principal
2. Configure GitHub Environments (dev and prd)
3. Add secrets to each environment:
   - `AZURE_CREDENTIALS`
   - `ARM_CLIENT_ID`
   - `ARM_CLIENT_SECRET`
   - `ARM_SUBSCRIPTION_ID`
   - `ARM_TENANT_ID`
4. Enable required approvers for prd environment

**Security:**
- ✅ Secrets only accessible from main branch
- ✅ PR builds cannot access production credentials
- ✅ Manual approval required for production deployments
- ✅ Protected main branch prevents unauthorized changes

#### Triggering Deployments

The pipeline runs automatically when:
- Changes are pushed to `main` branch affecting `infra/**`
- Pull requests target `main` with changes to `infra/**`
- Manually triggered via GitHub Actions UI

**Manual trigger:**
1. Go to **Actions** → **Terraform Deploy**
2. Click **Run workflow**
3. Select branch (must be `main` for deployments)
