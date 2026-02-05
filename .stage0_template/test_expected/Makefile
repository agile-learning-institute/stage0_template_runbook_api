.PHONY: help dev deploy down open validate execute get-token container tail

CONTAINER_IMAGE ?= ghcr.io/agile-learning-institute/mentorhub_runbook_api:latest
API_URL ?= http://localhost:8083
RUNBOOK ?= 
DATA ?= {"env_vars":{}}

help:
	@echo "Available commands:"
	@echo "  make container        - Build container with your runbooks"
	@echo "  make dev              - Run your runbook in Dev mode (Mounts ./runbooks)"
	@echo "  make deploy           - Run your runbook in Deploy mode (Packaged Runbooks)"
	@echo "  make down             - Shut down containers"
	@echo "  make open             - Open web UI in browser"
	@echo "  make tail             - Tail API logs (captures terminal, Ctrl+C to exit)"
	@echo "  make validate         - Validate a runbook (requires RUNBOOK=path/to/runbook.md)"
	@echo "  make execute          - Execute a runbook (requires RUNBOOK=path/to/runbook.md)"
	@echo ""
	@echo "Examples:"
	@echo "  make container && make dev"
	@echo "  make validate RUNBOOK=./runbooks/MyRunbook.md"
	@echo "  make execute RUNBOOK=./runbooks/MyRunbook.md DATA='{\"env_vars\":{\"VAR1\":\"value1\"}}'"
	@echo "  make deploy"

container:
	@echo "Building container image: $(CONTAINER_IMAGE)"
	@docker build -f Dockerfile -t $(CONTAINER_IMAGE) .
	@echo "Built: $(CONTAINER_IMAGE)"

dev:
	@echo "Shutting down centralized services..."
	@de down || true
	@echo "Starting local development services..."
	@export RUNBOOKS_DIR=$$(pwd)/runbooks && export JWT_SECRET=$$(date +%s) && docker compose up -d
	@$(MAKE) open

deploy:
	@$(MAKE) down || true
	@de up runbook
	@$(MAKE) open
	
down:
	@echo "Shutting down local containers..."
	@docker compose down || true
	@echo "Shutting down centralized services..."
	@de down || true

open:
	@echo "Opening web UI..."
	@open -a 'Google Chrome' 'http://localhost:8183' || google-chrome 'http://localhost:8183' || xdg-open 'http://localhost:8183'

get-token:
	@curl -s -X POST $(API_URL)/dev-login \
		-H "Content-Type: application/json" \
		-d '{"subject": "dev-user", "roles": ["sre", "api", "data", "ux"]}' \
		| jq -r '.access_token // .token // empty'

validate:
	@FILENAME=$$(basename $(RUNBOOK)); \
	TOKEN=$$(make -s get-token); \
	curl -s -X PATCH "$(API_URL)/api/runbooks/$$FILENAME/validate" \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		-d '$(DATA)' \
		| jq '.' || cat

execute:
	@FILENAME=$$(basename $(RUNBOOK)); \
	TOKEN=$$(make -s get-token); \
	curl -s -X POST "$(API_URL)/api/runbooks/$$FILENAME/execute" \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		-d '$(DATA)' \
		| jq '.' || cat

tail:
	@docker logs -f stage0_runbook_api