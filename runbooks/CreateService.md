# Create Service

This runbook creates GitHub repos for a domain from the architecture specification: for each repo in that domain with `type: api` or `type: spa` (skipping `type: spa_ref`), it creates the repo from its template, runs template merge processing, builds/pushes the container when applicable, and pushes the result.

**SERVICE_NAME:** The runbook clones the {{org.git_host}}/{{org.git_org}}/{{info.slug}} repo to get design specifications. `Specifications/architecture.yaml` and `Specifications/product.yaml` are used. `SERVICE_NAME` is a domain name that maps to a section of architecture.yaml. Repos within that domain with `type: api` or `type: spa` are processed; `type: spa_ref` repos are skipped. Created repo names are prefixed with `info.slug` from product.yaml (e.g. `mentorhub_mongodb_api`). Repos with an optional `publish` attribute run build/publish: `make build-publish` when `publish: make`, `npm run build-publish` when `publish: npm`, or `pipenv run build-publish` when `publish: pipenv`; repos without `publish` (e.g. libraries) are created and merged but not built or pushed. Organization and registry for git and registry login are read from `Specifications/product.yaml`.

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with ✅ repo, workflow, and write-package privileges
SERVICE_NAME: Domain name from architecture.yaml (e.g. mongodb)
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

# `RUNBOOK_EXEC_DIR_HOST` is provided by the Runbook Executor.
INITIAL_DIR=$(pwd)
REPO_HOST="${RUNBOOK_EXEC_DIR_HOST}"
MERGE_IMAGE="ghcr.io/{{org.git_org}}/stage0_runbook_merge:latest"
# --- Clone {{info.slug}} and resolve specs path ---
echo "Cloning {{info.slug}} for Specifications..."
git clone "https://${GITHUB_TOKEN}@github.com/{{org.git_org}}/{{info.slug}}.git" {{info.slug}} || { echo "Failed to clone {{info.slug}}"; exit 1; }
SPECS_DIR="$INITIAL_DIR/{{info.slug}}/Specifications"
ARCH_FILE="$SPECS_DIR/architecture.yaml"
PRODUCT_FILE="$SPECS_DIR/product.yaml"
SPECS_HOST="$REPO_HOST/{{info.slug}}/Specifications"

[[ -f "$ARCH_FILE" ]] || { echo "Error: Architecture file not found: $ARCH_FILE" >&2; exit 1; }
[[ -f "$PRODUCT_FILE" ]] || { echo "Error: Product file not found: $PRODUCT_FILE" >&2; exit 1; }

# --- From product.yaml: slug and org for repo naming; registry for login ---
SLUG=$(yq eval '.info.slug' "$PRODUCT_FILE")
GITHUB_ORG=$(yq eval '.organization.git_org' "$PRODUCT_FILE")
DOCKER_HOST=$(yq eval '.organization.docker_host' "$PRODUCT_FILE")
DOCKER_ORG=$(yq eval '.organization.docker_org' "$PRODUCT_FILE")

git config --global user.name "$GITHUB_ORG"
git config --global user.email "$GITHUB_ORG@users.noreply.github.com"
echo "Logging in to $DOCKER_HOST for container push..."
echo "$GITHUB_TOKEN" | docker login "$DOCKER_HOST" -u "${GITHUB_USER:-$DOCKER_ORG}" --password-stdin || { echo "Docker login failed (token needs write:packages)"; exit 1; }

# --- Repos for this domain (type=api or type=spa): name|template|publish (publish empty if not set) ---
REPO_LINES=$(yq eval '.architecture.domains[] | select(.name == env(SERVICE_NAME)) | .repos[] | select(.type == "api" or .type == "spa") | (.name + "|" + .template + "|" + (.publish // ""))' "$ARCH_FILE" 2>/dev/null) || true
[[ -n "$REPO_LINES" ]] || { echo "No repos with type api or spa found for domain: $SERVICE_NAME" >&2; exit 1; }

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  repo_name="${line%%|*}"
  rest="${line#*|}"
  template="${rest%%|*}"
  publish="${rest#*|}"
  REPO_FULL_NAME="${SLUG}_${repo_name}"
  REPO="$GITHUB_ORG/$REPO_FULL_NAME"

  echo "Creating $REPO from template $template"
  gh repo create "$REPO" --template "$template" --public --clone || { echo "Failed to create $REPO"; exit 1; }

  echo "Merging specifications into $REPO_FULL_NAME"
  cd "$INITIAL_DIR/$REPO_FULL_NAME"
  docker run --rm \
    -v "$REPO_HOST/$REPO_FULL_NAME:/repo" \
    -v "$SPECS_HOST:/specifications" \
    -e LOG_LEVEL=INFO \
    -e SERVICE_NAME=$SERVICE_NAME \
    "$MERGE_IMAGE" || { echo "Failed to merge $REPO_FULL_NAME"; exit 1; }

  if [[ -n "$publish" ]]; then
    echo "Running build-publish for $REPO_FULL_NAME (publish=$publish)"
    case "$publish" in
      make)   make build-publish || { echo "Failed to build/publish $REPO_FULL_NAME"; exit 1; } ;;
      npm)    npm run build-publish || { echo "Failed to build/publish $REPO_FULL_NAME"; exit 1; } ;;
      pipenv) pipenv run build-publish || { echo "Failed to build/publish $REPO_FULL_NAME"; exit 1; } ;;
      *)      echo "Unknown publish type: $publish - NOT PUBLISHED"; exit1; ;;
    esac
  else
    echo "No publish attribute for $REPO_FULL_NAME; skipping build/push"
  fi

  echo "Committing and pushing $REPO_FULL_NAME"
  git add -A
  git commit -m "Template Merge Processing Complete" || { echo "Failed to commit $REPO_FULL_NAME"; exit 1; }
  git remote set-url origin "https://${GITHUB_TOKEN}@github.com/$REPO.git"
  git push origin main || { echo "Failed to push $REPO_FULL_NAME"; exit 1; }
  echo "Successfully created and pushed: $REPO"

  cd "$INITIAL_DIR"
done <<< "$REPO_LINES"

echo "Done. Processed domain: $SERVICE_NAME"
```

# History