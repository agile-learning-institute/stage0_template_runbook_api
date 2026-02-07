# Create Service

This runbook creates GitHub repos for a domain from the architecture specification: for each repo in that domain with `type: api` or `type: spa` (skipping `type: spa_ref`), it creates the repo from its template, runs template merge processing, builds/pushes the container when applicable, and pushes the result.

**Context:** The runbook clones the https://github.com/agile-learning-institute/mentorhub repo to get design specifications. `Specifications/architecture.yaml` and `Specifications/product.yaml` are used. `CONTEXT` is a domain name that maps to a section of architecture.yaml. Repos within that domain with `type: api` or `type: spa` are processed; `type: spa_ref` repos are skipped. Created repo names are prefixed with `info.slug` from product.yaml (e.g. `mentorhub_mongodb_api`). Organization and registry values (`git_org`, `docker_host`, `docker_org`) are read from `Specifications/product.yaml`.

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with ✅ repo, workflow, and write-package privileges
CONTEXT: Domain name from architecture.yaml (e.g. mongodb)
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

# `RUNBOOK_EXEC_DIR_HOST` is provided by the API (host path for this run’s execution directory).
INITIAL_DIR=$(pwd)
REPO_HOST="$RUNBOOK_EXEC_DIR_HOST"
MERGE_IMAGE="ghcr.io/agile-learning-institute/stage0_runbook_merge:latest"
TAG=latest

# --- Clone mentorhub and resolve specs path ---
echo "Cloning mentorhub for Specifications..."
git clone "https://${GITHUB_TOKEN}@github.com/agile-learning-institute/mentorhub.git" mentorhub || { echo "Failed to clone mentorhub"; exit 1; }
SPECS_DIR="$INITIAL_DIR/mentorhub/Specifications"
ARCH_FILE="$SPECS_DIR/architecture.yaml"
PRODUCT_FILE="$SPECS_DIR/product.yaml"
SPECS_HOST="$REPO_HOST/mentorhub/Specifications"

if [[ ! -f "$ARCH_FILE" ]]; then
  echo "Error: Architecture file not found: $ARCH_FILE" >&2
  exit 1
fi
if [[ ! -f "$PRODUCT_FILE" ]]; then
  echo "Error: Product file not found: $PRODUCT_FILE" >&2
  exit 1
fi

# --- Organization and registry from product.yaml ---
SLUG=$(yq eval '.info.slug' "$PRODUCT_FILE")
GITHUB_ORG=$(yq eval '.organization.git_org' "$PRODUCT_FILE")
DOCKER_HOST=$(yq eval '.organization.docker_host' "$PRODUCT_FILE")
DOCKER_ORG=$(yq eval '.organization.docker_org' "$PRODUCT_FILE")

# --- Configure git identity for commits ---
git config --global user.name "$GITHUB_ORG"
git config --global user.email "$GITHUB_ORG@users.noreply.github.com"

# --- Log in to container registry ---
echo "Logging in to $DOCKER_HOST for container push..."
echo "$GITHUB_TOKEN" | docker login "$DOCKER_HOST" -u "${GITHUB_USER:-$DOCKER_ORG}" --password-stdin || { echo "Docker login failed (token needs write:packages)"; exit 1; }

# --- Resolve repos for this domain (type=api or type=spa only) ---
REPO_LINES=$(yq eval '.architecture.domains[] | select(.name == env(CONTEXT)) | .repos[] | select(.type == "api" or .type == "spa") | (.name + "|" + .template)' "$ARCH_FILE" 2>/dev/null) || true
if [[ -z "$REPO_LINES" ]]; then
  echo "No repos with type api or spa found for domain: $CONTEXT" >&2
  exit 1
fi

# --- Process each repo (loop in main shell so exit 1 aborts script) ---
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  repo_name="${line%%|*}"
  template="${line##*|}"
  REPO_FULL_NAME="${SLUG}_${repo_name}"
  REPO="$GITHUB_ORG/$REPO_FULL_NAME"

  echo "Creating $REPO from template $template"
  gh repo create "$REPO" --template "$template" --public --clone || { echo "Failed to create $REPO"; exit 1; }

  echo "Entering $REPO_FULL_NAME and merging specifications"
  cd "$INITIAL_DIR/$REPO_FULL_NAME"
  docker run --rm \
    -v "$REPO_HOST/$REPO_FULL_NAME:/repo" \
    -v "$SPECS_HOST:/specifications" \
    -e LOG_LEVEL=INFO \
    "$MERGE_IMAGE" || { echo "Failed to merge $REPO_FULL_NAME"; exit 1; }

  SERVICE_IMAGE="$DOCKER_HOST/$DOCKER_ORG/$REPO_FULL_NAME:$TAG"
  echo "Building and pushing $SERVICE_IMAGE"
  # Legacy builder avoids "driver not connecting" when client runs in container
  DOCKER_BUILDKIT=0 docker build -f Dockerfile -t "$SERVICE_IMAGE" . || { echo "Failed to build $REPO_FULL_NAME container"; exit 1; }
  docker push "$SERVICE_IMAGE" || { echo "Failed to push $REPO_FULL_NAME container"; exit 1; }
  echo "Service container built and pushed"

  echo "Committing and pushing $REPO_FULL_NAME"
  git add -A
  git commit -m "Template Merge Processing Complete" || { echo "Failed to commit $REPO_FULL_NAME"; exit 1; }
  git remote set-url origin "https://${GITHUB_TOKEN}@github.com/$REPO.git"
  git push origin main || { echo "Failed to push $REPO_FULL_NAME"; exit 1; }
  echo "Successfully created and pushed: $REPO"

  cd "$INITIAL_DIR"
done <<< "$REPO_LINES"

echo "Done. Processed domain: $CONTEXT"
```

# History