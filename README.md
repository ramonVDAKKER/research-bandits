# Research bandits evaluation

This repository supports the run of Monte Carlo simulation studies for 
contextual bandits, the storage of the results, and dashboarding to compare and visualize performances of selected methods and setups discussed in the following papers:
- [Valid Post-Contextual Bandit Inference](https://arxiv.org/abs/2505.13897)

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ramonVDAKKER/research-bandits.git
   cd research-bandits
   ```

2. **Install dependencies:**
   ```bash
   # Install uv if not already installed
   curl -LsSf https://astral.sh/uv/install.sh | sh

   # Install Python dependencies
   uv sync
   ```

3. **Run locally:**
   TO DO

## 1. Features

- Monte Carlo study to investigate performances of proposed methodologies.
- Dashboard to visualize the results.

## 2. Running the dashboard locally

### 2.1 Requirements

- Linux/WSL2
- Docker
- Python 3.13+
- uv
- Make

### 2.2 Run dashboard

TO DO

## 3. Development or deployment as Azure App Service

### 3.1 Requirements

Those in Section 2.1 plus:

- [pre-commit](https://pre-commit.com/) (for code quality hooks)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 2.0+
- [Terraform](https://www.terraform.io/downloads) 1.0+

### 3.2 Azure infrastructure

This project uses Terraform to manage Azure infrastructure with separate dev and prd environments. These environments correspond to different Resource Groups, but are organized within the same Azure subscription.

### Terraform Backend Setup

The Terraform code is organized as follows:

```
infra/
├── environments/
│   ├── dev/          # Development environment
│   └── prd/          # Production environment
├── modules/          # Shared Terraform modules
└── scripts/          # Infrastructure automation scripts
```

#### Initial Backend Setup (to be used locally; one-off)

1. Configure environment variables in `infra/scripts/.env`:
   ```bash
   cp infra/scripts/.env.example infra/scripts/.env
   ```
   And edit the .env-file with your values.

2. Use Azure CLI authentication:
   ```bash
   az login
   ```

2. Create the backend infrastructure:
   ```bash
   make terraform-init-backend
   ```

   This creates:
   - Resource group: `rg-terraform-state`
   - Storage accounts: `sttfstatebanditsdev`, `sttfstatebanditsprd`
   - Blob containers with tfstate files


#### Working with Terraform

**Local Development (Dev Environment):**

You can use the CI/CD pipeline (see Section TO DO), but for the
Dev environment you can also use the following Make commands as shortcut:

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

#### Common Tags

All Azure resources are tagged with:
- `Project`: research-bandits
- `Environment`: dev/prd
- `ManagedBy`: Terraform

## 3.3 CI/CD Pipelines

### 3.3.1 CI/CD Pipelines for infra

#### Deploy

Infrastructure deployments to production are managed via the GitHub Actions workflow `.github/workflows/terraform-deploy.yml`.

Pipeline Flow:
```
PR → main → Dev (manual approval required) → Prd (manual approval required)
```

#### Destroy

A dedicated workflow allows safe destruction of infrastructure through the GitHub Actions workflow `.github/workflows/terraform-destroy.yml`.
This pipeline can only be triggered manually and contains some guardrails.

Note: backend storage (i.e. tfstate) is NOT destroyed by this workflow.

### 3.3.2 CI/CD Pipelines for app

The project uses GitHub Actions workflows for:
1. **Linting** - Code quality checks using pre-commit hooks
2. **Testing** - Running pytest for both backend and frontend
3. **Security Scanning** - Vulnerability scanning with Trivy, Bandit, and pip-audit
4. **Building** - Building Docker images and pushing to Azure Container Registry
5. **Deployment** - Deploying backend (Container App Job) and frontend (App Service)
