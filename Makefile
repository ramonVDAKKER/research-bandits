.PHONY: lint docker-build docker-up docker-down docker-logs docker-restart docker-clean test terraform-init-backend terraform-init terraform-plan terraform-apply terraform-destroy acr-login-dev

# Development commands
lint:
	@echo "Running linter..."
	uv run --with pre-commit pre-commit run --all-files
	@echo "Linting complete."

test:
	@echo "Running tests..."
	uv run --group dev pytest --cov=src --cov-report=term-missing --cov-report=html
	@echo "Tests complete."

# Docker Compose commands
docker-build:
	@echo "Building Docker images..."
	docker-compose build
	@echo "Build complete."

docker-up:
	@echo "Starting services..."
	docker-compose up -d
	@echo "Services started. Frontend: http://localhost:8000"

docker-down:
	@echo "Stopping services..."
	docker-compose down
	@echo "Services stopped."

docker-logs:
	@echo "Showing logs..."
	docker-compose logs -f

docker-restart: docker-down docker-build docker-up
	@echo "Services restarted."

docker-clean:
	@echo "Cleaning up Docker resources..."
	docker-compose down -v
	docker system prune -f
	@echo "Cleanup complete."

# Run backend batch job manually
docker-run-backend:
	@echo "Running backend batch job..."
	docker run --rm -v research-bandits_shared-data:/data research-bandits-backend --rows 1000 --cols 10
	@echo "Batch job complete."

# Create Terraform backend (creates storage accounts for both dev and prd)
terraform-init-backend:
	@echo "Initializing Terraform backend on Azure..."
	@cd infra/scripts && bash init-terraform-backend-on-azure.sh
	@echo "Backend initialization complete."

# Load environment variables from .env file
-include infra/scripts/.env
export

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
		if [ -n "$(ACR_ALLOWED_IPS)" ]; then \
			terraform plan -var='acr_allowed_ips=[$(shell echo $(ACR_ALLOWED_IPS) | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$$/"/')]'; \
		else \
			terraform plan; \
		fi

terraform-apply:
	@echo "Applying Terraform changes for dev environment..."
	@if [ -z "$(ACR_ALLOWED_IPS)" ]; then \
		echo "⚠️  WARNING: ACR_ALLOWED_IPS not set in infra/scripts/.env"; \
		echo "ACR will be created with no IP restrictions (not recommended)"; \
	fi
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		if [ -n "$(ACR_ALLOWED_IPS)" ]; then \
			terraform apply -var='acr_allowed_ips=[$(shell echo $(ACR_ALLOWED_IPS) | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$$/"/')]'; \
		else \
			terraform apply; \
		fi

terraform-destroy:
	@echo "⚠️  WARNING: This will destroy all dev infrastructure!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "Destroying dev infrastructure..."
	@cd infra/environments/dev && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		if [ -n "$(ACR_ALLOWED_IPS)" ]; then \
			terraform destroy -var='acr_allowed_ips=[$(shell echo $(ACR_ALLOWED_IPS) | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$$/"/')]'; \
		else \
			terraform destroy; \
		fi

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
