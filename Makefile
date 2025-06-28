# Common variables to reduce duplication
# Load environment from .env file if it exists
LOAD_ENV := if [ -f .env ]; then set -a; source .env; set +a; fi;
SERVER_PID_FILE := .server.pid
SERVER_LOG_FILE := server.log

# Docker environment management
.PHONY: dev-up
dev-up: ## Start development environment with Docker Compose
	@echo "Starting Docker Compose environment..."
	@docker compose up -d
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 3
	@docker compose ps

.PHONY: dev-down
dev-down: ## Stop and remove Docker Compose environment
	@echo "Stopping Docker Compose environment..."
	@docker compose down

.PHONY: dev-logs
dev-logs: ## Show Docker Compose logs
	@docker compose logs -f

.PHONY: dev-reset
dev-reset: ## Reset Docker Compose environment (removes volumes)
	@echo "Resetting Docker Compose environment..."
	@docker compose down -v
	@echo "Environment reset. Run 'make dev-up' to start fresh."

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: test
test: ## Run tests. Use TAGS=integration for integration tests, PACKAGE=./postgres/... to test specific packages
	@if [ -n "$(TAGS)" ]; then \
		echo "Running tests with tags: $(TAGS)"; \
		if [ -z "$$TEST_DATABASE_URL" ] && echo "$(TAGS)" | grep -q "integration\|e2e"; then \
			echo "Error: TEST_DATABASE_URL must be set for integration/e2e tests"; \
			exit 1; \
		fi; \
	else \
		echo "Running unit tests..."; \
	fi
	@bash -c 'set -e; $(LOAD_ENV) \
	go test $(if $(RACE),-race) $(if $(V),-v) $(if $(TAGS),-tags $(TAGS)) $(if $(PACKAGE),$(PACKAGE),./...) $(ARGS)'

.PHONY: test-unit
test-unit: ## Run unit tests only
	@$(MAKE) test

.PHONY: test-integration
test-integration: ## Run integration tests (requires TEST_DATABASE_URL)
	@$(MAKE) test TAGS=integration V=1

.PHONY: test-all
test-all: ## Run all tests including integration (requires TEST_DATABASE_URL)
	@$(MAKE) test TAGS=integration

.PHONY: test-race
test-race: ## Run tests with race detector. Use TAGS=integration for integration tests
	@$(MAKE) test RACE=1

.PHONY: test-e2e
test-e2e: ## Run E2E tests. Use BASE_URL=<url> to test deployed service
	@if [ -n "$(BASE_URL)" ]; then \
		echo "Testing against: $(BASE_URL)"; \
	else \
		echo "Testing with local server (requires TEST_DATABASE_URL)"; \
		if [ -z "$$TEST_DATABASE_URL" ]; then \
			echo "Error: TEST_DATABASE_URL must be set for local E2E tests"; \
			exit 1; \
		fi; \
	fi
	@bash -c 'set -e; $(LOAD_ENV) \
	BASE_URL="$(BASE_URL)" AUTH_TOKEN="$(AUTH_TOKEN)" AUTH_TYPE="$(AUTH_TYPE)" \
	go test $(if $(RACE),-race) -v -tags=e2e ./cmd/server/... $(ARGS)'

.PHONY: server-start
server-start: ## Start server in background (requires .env file)
	@if [ -f $(SERVER_PID_FILE) ] && kill -0 $$(cat $(SERVER_PID_FILE)) 2>/dev/null; then \
		echo "Server already running (PID: $$(cat $(SERVER_PID_FILE)))"; \
		exit 1; \
	fi
	@echo "Starting server..."
	@bash -c '$(LOAD_ENV) go run ./cmd/server > $(SERVER_LOG_FILE) 2>&1 & echo $$! > $(SERVER_PID_FILE)'
	@sleep 3
	@if kill -0 $$(cat $(SERVER_PID_FILE)) 2>/dev/null; then \
		SERVER_PID=$$(lsof -ti:8080 2>/dev/null | head -1); \
		if [ -n "$$SERVER_PID" ]; then \
			echo "$$SERVER_PID" > $(SERVER_PID_FILE); \
			echo "Server started (PID: $$SERVER_PID)"; \
		else \
			echo "Server started (PID: $$(cat $(SERVER_PID_FILE)))"; \
		fi; \
		echo "Logs: tail -f $(SERVER_LOG_FILE)"; \
	else \
		echo "Server failed to start. Check $(SERVER_LOG_FILE) for details"; \
		rm -f $(SERVER_PID_FILE); \
		exit 1; \
	fi

.PHONY: server-stop
server-stop: ## Stop background server
	@echo "Stopping all processes on port 8080..."
	@PIDS=$$(lsof -ti:8080 2>/dev/null || echo ""); \
	if [ -n "$$PIDS" ]; then \
		echo "Found processes: $$PIDS"; \
		for PID in $$PIDS; do \
			echo "Stopping process $$PID..."; \
			kill $$PID 2>/dev/null; \
		done; \
		sleep 2; \
		REMAINING_PIDS=$$(lsof -ti:8080 2>/dev/null || echo ""); \
		if [ -n "$$REMAINING_PIDS" ]; then \
			echo "Some processes still running, force-stopping: $$REMAINING_PIDS"; \
			for PID in $$REMAINING_PIDS; do \
				echo "Force-stopping process $$PID..."; \
				kill -9 $$PID 2>/dev/null || echo "Failed to force-stop $$PID"; \
			done; \
			sleep 1; \
		fi; \
		FINAL_CHECK=$$(lsof -ti:8080 2>/dev/null || echo ""); \
		if [ -z "$$FINAL_CHECK" ]; then \
			echo "All server processes stopped successfully"; \
		else \
			echo "Warning: Some processes may still be running: $$FINAL_CHECK"; \
		fi; \
	else \
		echo "No processes found on port 8080"; \
	fi
	@rm -f $(SERVER_PID_FILE)

.PHONY: server-logs
server-logs: ## Tail server logs
	@if [ -f $(SERVER_LOG_FILE) ]; then \
		tail -f $(SERVER_LOG_FILE); \
	else \
		echo "No $(SERVER_LOG_FILE) file found"; \
	fi

.PHONY: server-restart
server-restart: server-stop server-start ## Restart background server


# PostgreSQL test database targets (Docker)
.PHONY: test-db-create
test-db-create: ## Create test database (handled automatically by Docker)
	@echo "Test database is automatically created by Docker Compose"
	@echo "Database: example_test"

.PHONY: test-db-reset
test-db-reset: ## Reset test database (drop and recreate)
	@docker compose exec -T postgres psql -U example -c "DROP DATABASE IF EXISTS example_test;"
	@docker compose exec -T postgres psql -U example -c "CREATE DATABASE example_test;"
	@docker compose exec -T postgres psql -U example -c "GRANT ALL PRIVILEGES ON DATABASE example_test TO example;"
	@echo "Test database reset"

.PHONY: setup-test
setup-test: dev-up ## Setup test environment with Docker PostgreSQL
	@echo "Test environment ready!"
	@echo "Run 'make test TAGS=integration' to run integration tests"
	@echo "Run 'make test TAGS=integration PACKAGE=./postgres/...' to run specific package tests"

.PHONY: lint
lint: ## Run golangci-lint
	golangci-lint run ./...

.PHONY: lint-fix
lint-fix: ## Run golangci-lint with auto-fix
	golangci-lint run --fix ./...


.PHONY: lint-workflows
lint-workflows: ## Lint GitHub Actions workflow files with actionlint
	@ACTIONLINT_BIN=~/go/bin/actionlint; \
	if ! command -v actionlint > /dev/null 2>&1; then \
		if [ -f $$ACTIONLINT_BIN ]; then \
			echo "Linting GitHub Actions workflows..."; \
			$$ACTIONLINT_BIN; \
		else \
			echo "Installing actionlint..."; \
			go install github.com/rhysd/actionlint/cmd/actionlint@latest; \
			echo "Linting GitHub Actions workflows..."; \
			$$ACTIONLINT_BIN; \
		fi \
	else \
		echo "Linting GitHub Actions workflows..."; \
		actionlint; \
	fi

.PHONY: templ-generate
templ-generate: ## Generate Go code from Templ templates
	@echo "Generating Templ templates..."
	@go run github.com/a-h/templ/cmd/templ generate

.PHONY: templ-watch
templ-watch: ## Watch and regenerate Templ templates on changes
	@echo "Watching Templ templates for changes..."
	@go run github.com/a-h/templ/cmd/templ generate --watch

.PHONY: validate
validate: templ-generate ## Run all validation checks (format, vet, test, lint)
	@echo "Running validation checks..."
	@echo "1. Generating templates..."
	@$(MAKE) templ-generate
	@echo "2. Formatting..."
	@go fmt ./...
	@echo "3. Vetting..."
	@go vet ./...
	@echo "4. Testing..."
	@go test ./...
	@echo "5. Tidying modules..."
	@go mod tidy
	@echo "6. Linting..."
	@golangci-lint run ./...
	@echo "7. Linting workflows..."
	@$(MAKE) lint-workflows
	@echo "✅ All validation checks passed!"

.PHONY: validate-ci
validate-ci: templ-generate ## Run validation checks in CI mode (fail on any issue)
	@echo "Running CI validation checks..."
	@echo "Generating templates..."
	@$(MAKE) templ-generate
	@echo "Checking formatting..."
	@if [ -n "$$(go fmt ./...)" ]; then \
		echo "❌ Code needs formatting. Run 'go fmt ./...'"; \
		exit 1; \
	fi
	@echo "Running go vet..."
	@go vet ./...
	@echo "Running tests..."
	@go test ./...
	@echo "Checking go.mod..."
	@go mod tidy
	@if [ -n "$$(git status --porcelain go.mod go.sum)" ]; then \
		echo "❌ go.mod/go.sum need updating. Run 'go mod tidy'"; \
		exit 1; \
	fi
	@echo "Running linter..."
	@golangci-lint run ./...
	@echo "✅ All CI validation checks passed!"

# OpenTofu infrastructure targets
.PHONY: tf-init
tf-init: ## Initialize OpenTofu configuration
	cd terraform && tofu init

.PHONY: tf-validate
tf-validate: ## Validate OpenTofu configuration
	cd terraform && tofu init -backend=false && tofu validate

.PHONY: tf-test
tf-test: ## Run OpenTofu tests
	cd terraform && tofu test -var-file=tests/test.tfvars

.PHONY: tf-plan
tf-plan: ## Create OpenTofu execution plan
	cd terraform && tofu plan

.PHONY: tf-apply
tf-apply: ## Apply OpenTofu changes
	cd terraform && tofu apply -auto-approve

