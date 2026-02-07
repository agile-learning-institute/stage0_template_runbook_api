# Create Product

This runbook creates the Umbrella and Runbook repo's for a new Stage0 Launch-able product. 
The PRODUCT_YAML environment variable should contain something similar to:
```yaml
info:
  name: Test Product Name
  description: Test Product Description
  slug: test
  developer_cli: te
  db_name: test_name
  base_port: 9090

organization:
  name: Test Organization Name
  founded: 1234
  slug: org-slug test
  git_host: https://github.com
  git_org: agile-learning-institute
  docker_host: ghcr.io
  docker_org: agile-learning-institute
```

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with ✅ repo, workflow, and write-package privileges
PRODUCT_YAML: The product.yaml content (see above)
```

# File System Requirements
```yaml
Input:
```

# Required Claims
```yaml
roles: sre
```

# Script
```sh
#!/usr/bin/env zsh
set -e

# --- Write product spec and parse slug/org ---
mkdir -p ./Specifications
echo "$PRODUCT_YAML" > ./Specifications/product.yaml
cat ./Specifications/product.yaml

# `RUNBOOK_EXEC_DIR_HOST` is provided by the API (host path for this run’s execution directory).
SLUG=$(yq eval '.info.slug' ./Specifications/product.yaml)
ORG=$(yq eval '.organization.git_org' ./Specifications/product.yaml)
DOCKER_ORG=$(yq eval '.organization.docker_org' ./Specifications/product.yaml)
DOCKER_HOST=$(yq eval '.organization.docker_host' ./Specifications/product.yaml)
REPO="$ORG/$SLUG"
INITIAL_DIR=$(pwd)
REPO_HOST="$RUNBOOK_EXEC_DIR_HOST"
SPECS_HOST="$RUNBOOK_EXEC_DIR_HOST/Specifications"
MERGE_IMAGE="ghcr.io/agile-learning-institute/stage0_runbook_merge:latest"
TAG=latest

# --- Configure git identity for commits (GitHub noreply so gh/git operations succeed) ---
git config --global user.name "$ORG"
git config --global user.email "$DOCKER_ORG@users.noreply.github.com"

# --- Log in to container registry (ghcr.io) so make push works ---
echo "Logging in to ghcr.io for container push..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_USER:-$DOCKER_ORG}" --password-stdin || { echo "Docker login failed (token needs write:packages)"; exit 1; }

# --- Create and set up umbrella repo ---
TEMPLATE="agile-learning-institute/stage0_template_umbrella"
echo "Creating $REPO from $TEMPLATE"
gh repo create "$REPO" --template "$TEMPLATE" --public --clone || { echo "Failed to create umbrella repo"; exit 1; }

echo "Entering $SLUG and merging specifications"
cd "$SLUG"
docker run --rm \
  -v "$REPO_HOST/$SLUG:/repo" \
  -v "$SPECS_HOST:/specifications" \
  -e LOG_LEVEL=INFO \
  "$MERGE_IMAGE" || { echo "Failed to merge umbrella"; exit 1; }

UMBRELLA_IMAGE="$DOCKER_HOST/$DOCKER_ORG/$SLUG:$TAG"
echo "Building and pushing $UMBRELLA_IMAGE"
# Build context: current dir (we are in $SLUG). Legacy builder avoids "driver not connecting" when client runs in container.
DOCKER_BUILDKIT=0 docker build -t "$UMBRELLA_IMAGE" . || { echo "Failed to build umbrella container"; exit 1; }
docker push "$UMBRELLA_IMAGE" || { echo "Failed to push umbrella container"; exit 1; }
echo "Umbrella container built and pushed"

echo "Committing and pushing umbrella repo"
git add -A
git commit -m "Template Merge Processing Complete" || { echo "Failed to commit umbrella"; exit 1; }
git remote set-url origin "https://${GITHUB_TOKEN}@github.com/$REPO.git"
git push origin main || { echo "Failed to push umbrella repo"; exit 1; }
echo "Successfully created umbrella repo: $REPO"

# --- Create and set up runbook_api repo ---
cd "$INITIAL_DIR"
REPO="$ORG/${SLUG}_runbook_api"
TEMPLATE="agile-learning-institute/stage0_template_runbook_api"

echo "Creating $REPO from $TEMPLATE"
gh repo create "$REPO" --template "$TEMPLATE" --private --clone || { echo "Failed to create runbook_api repo"; exit 1; }

echo "Entering ${SLUG}_runbook_api and merging specifications"
cd "${SLUG}_runbook_api"
docker run --rm \
  -v "$REPO_HOST/${SLUG}_runbook_api:/repo" \
  -v "$SPECS_HOST:/specifications" \
  -e LOG_LEVEL=INFO \
  "$MERGE_IMAGE" || { echo "Failed to merge runbook_api"; exit 1; }

API_IMAGE="$DOCKER_HOST/$DOCKER_ORG/${SLUG}_runbook_api:$TAG"
echo "Building and pushing $API_IMAGE"
# Legacy builder avoids "driver not connecting" when client runs in container
DOCKER_BUILDKIT=0 docker build -f Dockerfile -t "$API_IMAGE" . || { echo "Failed to build runbook_api container"; exit 1; }
docker push "$API_IMAGE" || { echo "Failed to push runbook_api container"; exit 1; }
echo "Runbook API container built and pushed"

echo "Committing and pushing runbook_api repo"
git add -A
git commit -m "Template Merge Processing Complete" || { echo "Failed to commit runbook_api"; exit 1; }
git remote set-url origin "https://${GITHUB_TOKEN}@github.com/$REPO.git"
git push origin main || { echo "Failed to push runbook_api repo"; exit 1; }
echo "Successfully created runbook_api repo: $REPO"

echo "Done. Umbrella: $ORG/$SLUG — Runbook API: $REPO"
```

# History
