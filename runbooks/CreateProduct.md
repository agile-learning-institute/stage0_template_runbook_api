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
#! /bin/zsh

# Create umbrella repo
echo $PRODUCT_YAML > ./Specifications/product.yaml 
$REPO = yq ./Specifications/product.yaml info.slug 
$TEMPLATE = agile-learning-institute/stage0_template_umbrella

echo "Creating $REPO from $TEMPLATE "                   && \
gh repo create $REPO --template $TEMPLATE --private     && \
echo "Cloning $REPO"                                    && \
git clone $REPO                                         && \
cd into $REPO_NAME                                      && \
echo "Merging $REPO"                                    && \
make merge ../Specifications                            && \
echo "Committing Changes to $REPO"                      && \
git add *                                               && \
git commit "Template Merge Processing Complete"         && \
git push && cd ..                                       && \
echo "Successfully Created Umbrella Repo" || exit 1 "Failed to create umbrella project"

# Create umbrella repo
$REPO = "runbook_api" 
$TEMPLATE = agile-learning-institute/stage0_template_runbook_api

echo "Creating $REPO from $TEMPLATE "                   && \
gh repo create $REPO --template $TEMPLATE --private     && \
echo "Cloning $REPO"                                    && \
git clone $REPO                                         && \
cd into $REPO_NAME                                      && \
echo "Merging $REPO"                                    && \
make merge ../Specifications                            && \
echo "Committing Changes to $REPO"                      && \
git add *                                               && \
git commit "Template Merge Processing Complete"         && \
git push && cd ..                                       && \
echo "Successfully Created runbook_api Repo" || exit 1 "Failed to create runbook_api Repo"

echo "Building and pushing container for CI"
make container                                          && \
make push                                               && \
echo "Container Built and Pushed" || exit 1 "Failed to build and push runbook api container image"
```

# History
