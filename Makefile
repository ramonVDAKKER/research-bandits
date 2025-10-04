.PHONY: lint terraform-init-backend terraform-init terraform-plan terraform-apply terraform-destroy acr-login-dev

lint:
	@echo "Running linter..."
	pre-commit run --all-files
	@echo "Linting complete."

# Create Terraform backend (creates storage accounts for both dev and prd)
terraform-init-backend:
	@echo "Initializing Terraform backend on Azure..."
	@cd infra/scripts && bash init-terraform-backend-on-azure.sh
	@echo "Backend initialization complete."

# Load environment variables from .env file
-include infra/scripts/.env
export

# Convert comma-separated IPs to Terraform list format
define TERRAFORM_VARS
	-var='acr_allowed_ips=[$(shell echo $(ACR_ALLOWED_IPS) | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$$/"/')]'
endef

# Terraform Dev Environment
terraform-init:
	@echo "Initializing Terraform for dev environment..."
	@cd infra/environments/dev && terraform init

terraform-plan:
	@echo "Planning Terraform changes for dev environment..."
	@if [ -z "$(ACR_ALLOWED_IPS)" ]; then \
		echo "⚠️  WARNING: ACR_ALLOWED_IPS not set in infra/scripts/.env"; \
		echo "ACR will be created with no IP restrictions (not recommended)"; \
	fi
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		terraform plan $(TERRAFORM_VARS)

terraform-apply:
	@echo "Applying Terraform changes for dev environment..."
	@if [ -z "$(ACR_ALLOWED_IPS)" ]; then \
		echo "⚠️  WARNING: ACR_ALLOWED_IPS not set in infra/scripts/.env"; \
		echo "ACR will be created with no IP restrictions (not recommended)"; \
	fi
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		terraform apply $(TERRAFORM_VARS)

terraform-destroy:
	@echo "⚠️  WARNING: This will destroy all dev infrastructure!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "Destroying dev infrastructure..."
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		terraform destroy $(TERRAFORM_VARS)

acr-login-dev:
	@echo "🔐 Logging into ACR (Dev environment)..."
	@cd infra/environments/dev && \
	ACR_NAME=$$(terraform output -raw acr_name 2>/dev/null) && \
	if [ -z "$$ACR_NAME" ]; then \
		echo "❌ Error: Could not get ACR name. Make sure Terraform has been applied."; \
		exit 1; \
	fi && \
	echo "📋 ACR Name: $$ACR_NAME" && \
	az acr login --name $$ACR_NAME && \
	echo "✅ Successfully logged into ACR: $$ACR_NAME"
