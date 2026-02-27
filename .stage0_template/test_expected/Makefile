.PHONY: help dev deploy down open validate execute get-token container push build-package publish-package delete-package tail
ORG ?= agile-learning-institute

CONTAINER_IMAGE ?= ghcr.io/agile-learning-institute/mentorhub_runbook_api:latest
API_URL ?= http://localhost:8384/
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
	@DOCKER_BUILDKIT=0 docker build -f Dockerfile -t $(CONTAINER_IMAGE) .
	@echo "Built: $(CONTAINER_IMAGE)"

push:
	@echo "Pushing container image: $(CONTAINER_IMAGE)"
	@docker push $(CONTAINER_IMAGE) 
	@echo "Pushed: $(CONTAINER_IMAGE)"

build-package: container
publish-package: push
delete-package:
	@echo "Deleting container package..."
	@gh api -X DELETE "/orgs//packages/container/mentorhub_runbook_api"

dev:
	@echo "Shutting down centralized services..."
	@mh down || true
	@echo "Starting local development services..."
	@mkdir -p execution
	@export MOUNT_DIR=$$(pwd)/execution && export JWT_SECRET=$$(date +%s) && docker compose up -d
	@$(MAKE) open

deploy:
	@$(MAKE) down || true
	@mh up runbook
	@$(MAKE) open
	
down:
	@echo "Shutting down local containers..."
	@export MOUNT_DIR=foo && export JWT_SECRET=bar && docker compose down || true
	@echo "Shutting down centralized services..."
	@mh down || true

open:
	@echo "Opening web UI..."
	@open -a 'Google Chrome' 'http://localhost:8384' || google-chrome 'http://localhost:8384' || xdg-open 'http://localhost:8384'

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