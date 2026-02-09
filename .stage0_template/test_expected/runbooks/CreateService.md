# Create Service

This runbook creates GitHub repos for a domain from the architecture specification: for each repo in that domain with `type: api` or `type: spa` (skipping `type: spa_ref`), it creates the repo from its template, runs template merge processing, builds/pushes the container when applicable, and pushes the result.

**Context:** The runbook clones the https://github.com/agile-learning-institute/mentorhub repo to get design specifications. `Specifications/architecture.yaml` and `Specifications/product.yaml` are used. `CONTEXT` is a domain name that maps to a section of architecture.yaml. Repos within that domain with `type: api` or `type: spa` are processed; `type: spa_ref` repos are skipped. Created repo names are prefixed with `info.slug` from product.yaml (e.g. `mentorhub_mongodb_api`). Docker image names come from each repo's `image` field in architecture.yaml; repos without `image` (e.g. libraries) are created and merged but not built or pushed. Organization and registry for git and registry login are read from `Specifications/product.yaml`.

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

# `RUNBOOK_EXEC_DIR_HOST` is provided by the Runbook Executor.
INITIAL_DIR=$(pwd)
REPO_HOST="${RUNBOOK_EXEC_DIR_HOST}"
MERGE_IMAGE="ghcr.io/agile-learning-institute/stage0_runbook_merge:latest"
# --- Clone mentorhub and resolve specs path ---
echo "Cloning mentorhub for Specifications..."
git clone "https://${GITHUB_TOKEN}@github.com/agile-learning-institute/mentorhub.git" mentorhub || { echo "Failed to clone mentorhub"; exit 1; }
SPECS_DIR="$INITIAL_DIR/mentorhub/Specifications"
ARCH_FILE="$SPECS_DIR/architecture.yaml"
PRODUCT_FILE="$SPECS_DIR/product.yaml"
SPECS_HOST="$REPO_HOST/mentorhub/Specifications"

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

# --- Repos for this domain (type=api or type=spa): name|template|image (image empty if not set) ---
REPO_LINES=$(yq eval '.architecture.domains[] | select(.name == env(CONTEXT)) | .repos[] | select(.type == "api" or .type == "spa") | (.name + "|" + .template + "|" + (.image // ""))' "$ARCH_FILE" 2>/dev/null) || true
[[ -n "$REPO_LINES" ]] || { echo "No repos with type api or spa found for domain: $CONTEXT" >&2; exit 1; }

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  repo_name="${line%%|*}"
  rest="${line#*|}"
  template="${rest%%|*}"
  image="${rest#*|}"
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
    "$MERGE_IMAGE" || { echo "Failed to merge $REPO_FULL_NAME"; exit 1; }

  if [[ -n "$image" ]]; then
    echo "Building and pushing $image"
    DOCKER_BUILDKIT=0 docker build -f Dockerfile -t "$image" . || { echo "Failed to build $REPO_FULL_NAME"; exit 1; }
    docker push "$image" || { echo "Failed to push $REPO_FULL_NAME"; exit 1; }
  else
    echo "No image in architecture for $REPO_FULL_NAME; skipping build/push"
  fi

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

### 2026-02-09T21:42:29.914Z | Exit Code: 0

**Stdout:**
```
Cloning mentorhub for Specifications...
Logging in to ghcr.io for container push...
Login Succeeded
Creating agile-learning-institute/mentorhub_api_utils from template agile-learning-institute/stage0_template_py_utils
https://github.com/agile-learning-institute/mentorhub_api_utils
Merging specifications into mentorhub_api_utils
No image in architecture for mentorhub_api_utils; skipping build/push
Committing and pushing mentorhub_api_utils
[main d06d879] Template Merge Processing Complete
 82 files changed, 213 insertions(+), 5781 deletions(-)
 delete mode 100644 .stage0_template/Specifications/architecture.yaml
 delete mode 100644 .stage0_template/Specifications/catalog.yaml
 delete mode 100644 .stage0_template/Specifications/product.yaml
 delete mode 100644 .stage0_template/process.yaml
 delete mode 100644 .stage0_template/test_expected/.gitignore
 delete mode 100644 .stage0_template/test_expected/LICENSE
 delete mode 100644 .stage0_template/test_expected/Pipfile
 delete mode 100644 .stage0_template/test_expected/Pipfile.lock
 delete mode 100644 .stage0_template/test_expected/README.md
 delete mode 100644 .stage0_template/test_expected/SECURITY.md
 delete mode 100644 .stage0_template/test_expected/api_utils/__init__.py
 delete mode 100644 .stage0_template/test_expected/api_utils/config/__init__.py
 delete mode 100644 .stage0_template/test_expected/api_utils/config/config.py
 delete mode 100644 .stage0_template/test_expected/api_utils/flask_utils/__init__.py
 delete mode 100644 .stage0_template/test_expected/api_utils/flask_utils/breadcrumb.py
 delete mode 100644 .stage0_template/test_expected/api_utils/flask_utils/ejson_encoder.py
 delete mode 100644 .stage0_template/test_expected/api_utils/flask_utils/exceptions.py
 delete mode 100644 .stage0_template/test_expected/api_utils/flask_utils/route_wrapper.py
 delete mode 100644 .stage0_template/test_expected/api_utils/flask_utils/token.py
 delete mode 100644 .stage0_template/test_expected/api_utils/mongo_utils/__init__.py
 delete mode 100644 .stage0_template/test_expected/api_utils/mongo_utils/encode_properties.py
 delete mode 100644 .stage0_template/test_expected/api_utils/mongo_utils/infinite_scroll.py
 delete mode 100644 .stage0_template/test_expected/api_utils/mongo_utils/mongo_io.py
 delete mode 100644 .stage0_template/test_expected/api_utils/routes/__init__.py
 delete mode 100644 .stage0_template/test_expected/api_utils/routes/config_routes.py
 delete mode 100644 .stage0_template/test_expected/api_utils/routes/dev_login_routes.py
 delete mode 100644 .stage0_template/test_expected/api_utils/routes/explorer_routes.py
 delete mode 100644 .stage0_template/test_expected/api_utils/routes/metric_routes.py
 delete mode 100644 .stage0_template/test_expected/api_utils/server.py
 delete mode 100644 .stage0_template/test_expected/docs/explorer.html
 delete mode 100644 .stage0_template/test_expected/docs/index.html
 delete mode 100644 .stage0_template/test_expected/docs/openapi.yaml
 delete mode 100644 .stage0_template/test_expected/pyproject.toml
 delete mode 100644 .stage0_template/test_expected/tests/config/test_config_defaults.py
 delete mode 100644 .stage0_template/test_expected/tests/config/test_config_env.py
 delete mode 100644 .stage0_template/test_expected/tests/config/test_config_file.py
 delete mode 100644 .stage0_template/test_expected/tests/config/test_config_jwt_secret.py
 delete mode 100644 .stage0_template/test_expected/tests/conftest.py
 delete mode 100644 .stage0_template/test_expected/tests/flask_utils/test_breadcrumb.py
 delete mode 100644 .stage0_template/test_expected/tests/flask_utils/test_ejson_encoder.py
 delete mode 100644 .stage0_template/test_expected/tests/flask_utils/test_exceptions.py
 delete mode 100644 .stage0_template/test_expected/tests/flask_utils/test_route_wrapper.py
 delete mode 100644 .stage0_template/test_expected/tests/flask_utils/test_token.py
 delete mode 100644 .stage0_template/test_expected/tests/mongo_utils/test_encode_properties.py
 delete mode 100644 .stage0_template/test_expected/tests/mongo_utils/test_infinite_scroll.py
 delete mode 100644 .stage0_template/test_expected/tests/mongo_utils/test_mongo_io.py
 delete mode 100644 .stage0_template/test_expected/tests/routes/test_config_routes.py
 delete mode 100644 .stage0_template/test_expected/tests/routes/test_dev_login_routes.py
 delete mode 100644 .stage0_template/test_expected/tests/test_data/config/ENABLE_LOGIN
 delete mode 100644 .stage0_template/test_expected/tests/test_data/config/JWT_TTL_MINUTES
 delete mode 100644 .stage0_template/test_expected/tests/test_data/config/MONGO_CONNECTION_STRING
 delete mode 100644 .stage0_template/test_expected/tests/test_data/config/MONGO_DB_NAME
 delete mode 100644 .stage0_template/test_expected/tests/test_data/config/OUTPUT_FOLDER
 delete mode 100644 .stage0_template/test_expected/tests/test_data/config/VERSIONS_COLLECTION_NAME
 delete mode 100644 .stage0_template/test_expected/tests/test_server.py
 delete mode 100644 Makefile
 delete mode 100644 README.md.template
 delete mode 100644 tests/test_data/config/API_PORT.template
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/COMMON_CODE_API_PORT (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/COMMON_CODE_SPA_PORT (100%)
 rename .stage0_template/test_expected/tests/test_data/config/ENUMERATORS_COLLECTION_NAME => tests/test_data/config/CURRICULUM_COLLECTION_NAME (100%)
 rename .stage0_template/test_expected/tests/test_data/config/IDENTITY_COLLECTION_NAME => tests/test_data/config/ENCOUNTER_COLLECTION_NAME (100%)
 rename .stage0_template/test_expected/tests/test_data/config/INPUT_FOLDER => tests/test_data/config/IDENTITY_COLLECTION_NAME (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/MONGODB_API_PORT (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/MONGODB_SPA_PORT (100%)
 rename .stage0_template/test_expected/tests/test_data/config/JWT_ALGORITHM => tests/test_data/config/PATH_COLLECTION_NAME (100%)
 rename .stage0_template/test_expected/tests/test_data/config/JWT_AUDIENCE => tests/test_data/config/PLAN_COLLECTION_NAME (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/PROFILE_COLLECTION_NAME (100%)
 rename .stage0_template/test_expected/tests/test_data/config/JWT_ISSUER => tests/test_data/config/RATING_COLLECTION_NAME (100%)
 rename .stage0_template/test_expected/tests/test_data/config/JWT_SECRET => tests/test_data/config/REVIEW_COLLECTION_NAME (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/RUNBOOK_API_PORT (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/RUNBOOK_SPA_PORT (100%)
 delete mode 100644 tests/test_data/config/SPA_PORT.template
 delete mode 100644 tests/test_data/config/STRING.template
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/TEMPLATE_API_PORT (100%)
 rename {.stage0_template/test_expected/tests => tests}/test_data/config/TEMPLATE_SPA_PORT (100%)
 rename .stage0_template/test_expected/tests/test_data/config/LOGGING_LEVEL => tests/test_data/config/TOPIC_COLLECTION_NAME (100%)
Successfully created and pushed: agile-learning-institute/mentorhub_api_utils
Creating agile-learning-institute/mentorhub_spa_utils from template agile-learning-institute/stage0_template_vue_utils
https://github.com/agile-learning-institute/mentorhub_spa_utils
Merging specifications into mentorhub_spa_utils
No image in architecture for mentorhub_spa_utils; skipping build/push
Committing and pushing mentorhub_spa_utils
[main 4ee0bbe] Template Merge Processing Complete
 10 files changed, 3 insertions(+), 442 deletions(-)
 delete mode 100644 .stage0_template/Specifications/architecture.yaml
 delete mode 100644 .stage0_template/Specifications/catalog.yaml
 delete mode 100644 .stage0_template/Specifications/product.yaml
 delete mode 100644 .stage0_template/process.yaml
 delete mode 100644 .stage0_template/test_expected/LICENSE
 delete mode 100644 .stage0_template/test_expected/README.md
 delete mode 100644 Makefile
 delete mode 100644 README.md.template
Successfully created and pushed: agile-learning-institute/mentorhub_spa_utils
Done. Processed domain: common_code

```

**Stderr:**
```
Cloning into 'mentorhub'...
Cloning into 'mentorhub_api_utils'...
INFO: Initialized, Specifications Folder: /specifications, Repo Folder: /repo, Logging Level: INFO
INFO: Process Loaded for 9 templates
INFO: Specifications Loaded from 6 documents
INFO: 0 Environment Variables loaded successfully.
INFO: 4 Data Contexts Established
INFO: Verified 8 required properties exist, go for processing
INFO: Processing /repo/LICENSE
INFO: Processing /repo/README.md.template
INFO: Building ./README.md
INFO: Processing /repo/Makefile
INFO: Building /dev/null
INFO: Processing /repo/Pipfile
INFO: Processing /repo/api_utils/config/config.py
INFO: Processing /repo/tests/test_server.py
INFO: Processing /repo/tests/test_data/config/STRING.template
INFO: Building ./tests/test_data/config/IDENTITY_COLLECTION_NAME
INFO: Building ./tests/test_data/config/PROFILE_COLLECTION_NAME
INFO: Building ./tests/test_data/config/CURRICULUM_COLLECTION_NAME
INFO: Building ./tests/test_data/config/ENCOUNTER_COLLECTION_NAME
INFO: Building ./tests/test_data/config/PLAN_COLLECTION_NAME
INFO: Building ./tests/test_data/config/PATH_COLLECTION_NAME
INFO: Building ./tests/test_data/config/RATING_COLLECTION_NAME
INFO: Building ./tests/test_data/config/REVIEW_COLLECTION_NAME
INFO: Building ./tests/test_data/config/TOPIC_COLLECTION_NAME
INFO: Processing /repo/tests/test_data/config/API_PORT.template
INFO: Building ./tests/test_data/config/RUNBOOK_API_PORT
INFO: Building ./tests/test_data/config/MONGODB_API_PORT
INFO: Building ./tests/test_data/config/COMMON_CODE_API_PORT
INFO: Building ./tests/test_data/config/TEMPLATE_API_PORT
INFO: Processing /repo/tests/test_data/config/SPA_PORT.template
INFO: Building ./tests/test_data/config/RUNBOOK_SPA_PORT
INFO: Building ./tests/test_data/config/MONGODB_SPA_PORT
INFO: Building ./tests/test_data/config/COMMON_CODE_SPA_PORT
INFO: Building ./tests/test_data/config/TEMPLATE_SPA_PORT
INFO: Removing /repo/.stage0_template
INFO: Completed - Processed 9 templates, wrote 23 files
To https://github.com/agile-learning-institute/mentorhub_api_utils.git
   e68ea90..d06d879  main -> main
Cloning into 'mentorhub_spa_utils'...
INFO: Initialized, Specifications Folder: /specifications, Repo Folder: /repo, Logging Level: INFO
INFO: Process Loaded for 3 templates
INFO: Specifications Loaded from 6 documents
INFO: 0 Environment Variables loaded successfully.
INFO: 4 Data Contexts Established
INFO: Verified 8 required properties exist, go for processing
INFO: Processing /repo/LICENSE
INFO: Processing /repo/README.md.template
INFO: Building ./README.md
INFO: Processing /repo/Makefile
INFO: Building /dev/null
INFO: Removing /repo/.stage0_template
INFO: Completed - Processed 3 templates, wrote 3 files
To https://github.com/agile-learning-institute/mentorhub_spa_utils.git
   e937d2e..4ee0bbe  main -> main

```
