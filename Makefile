.PHONY: lint terraform-init-backend terraform-init terraform-plan terraform-apply terraform-destroy

lint:
	@echo "Running linter..."
	pre-commit run --all-files
	@echo "Linting complete."

# Create Terraform backend (creates storage accounts for both dev and prd)
terraform-init-backend:
	@echo "Initializing Terraform backend on Azure..."
	@cd infra/scripts && bash init-terraform-backend-on-azure.sh
	@echo "Backend initialization complete."

# Terraform Dev Environment
terraform-init:
	@echo "Initializing Terraform for dev environment..."
	@cd infra/environments/dev && terraform init

terraform-plan:
	@echo "Planning Terraform changes for dev environment..."
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		terraform plan

terraform-apply:
	@echo "Applying Terraform changes for dev environment..."
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		terraform apply

terraform-destroy:
	@echo "⚠️  WARNING: This will destroy all dev infrastructure!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "Destroying dev infrastructure..."
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		terraform destroy
