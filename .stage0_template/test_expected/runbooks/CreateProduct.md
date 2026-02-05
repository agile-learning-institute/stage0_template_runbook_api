# Create Product

This runbook creates the Umbrella and Runbook repo's for a new Stage0 Launch-able product. 

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with ✅ repo Privileges
PRODUCT_YAML: The product.yaml content
```

# File System Requirements
```yaml
Input:
Output:
```

# Required Claims
```yaml
roles: sre
```

# Script
```sh
#!/usr/bin/env zsh
set -e

# --- Ensure GITHUB_TOKEN is set (gh and git use it; no login prompts) ---
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN is not set." >&2
  exit 1
fi

# --- Write product spec and parse slug/org ---
mkdir -p ./Specifications
echo "$PRODUCT_YAML" > ./Specifications/product.yaml

SLUG=$(yq eval '.info.slug' ./Specifications/product.yaml)
ORG=$(yq eval '.organization.git_org' ./Specifications/product.yaml)
DOCKER_ORG=$(yq eval '.organization.docker_org' ./Specifications/product.yaml)
REPO="$ORG/$SLUG"
INITIAL_DIR=$(pwd)

# --- Log in to container registry (ghcr.io) so make push works ---
echo "Logging in to ghcr.io for container push..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_USER:-$DOCKER_ORG}" --password-stdin || { echo "Docker login failed (token needs write:packages)"; exit 1; }

# --- Create and set up umbrella repo ---
TEMPLATE="agile-learning-institute/stage0_template_umbrella"
echo "Creating $REPO from $TEMPLATE"
gh repo create "$REPO" --template "$TEMPLATE" --public --clone || { echo "Failed to create umbrella repo"; exit 1; }

echo "Entering $SLUG and merging specifications"
cd "$SLUG"
make merge "$INITIAL_DIR/Specifications" || { echo "Failed to merge umbrella"; exit 1; }

echo "Building and pushing container for umbrella CI"
make container && make push || { echo "Failed to build/push umbrella container"; exit 1; }
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
make merge "$INITIAL_DIR/Specifications" || { echo "Failed to merge runbook_api"; exit 1; }

echo "Building and pushing container for runbook_api CI"
make container && make push || { echo "Failed to build/push runbook_api container"; exit 1; }
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
