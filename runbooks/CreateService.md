# Create Service

This runbook creates a GitHub Repo's from the Repo Templates, performs template merge processing, and pushes working code back to each new repo. 

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with ✅ repo Privileges
CONTEXT: The full name of the Context repo that contains Specifications
SERVICE: The service name from architecture.yaml specification
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

# Get the Context repo for Specifications
git clone $CONTEXT || exit 1 "Couldn't clone context repo $CONTEXT"

# Use yq to parse Specifications/architecture.yaml find service
# for each repo in service
    # Only process api and spa type repo's
    if service.type not in api, spa next

    # Create repo from template
    echo "Using GitHub CLI Version $(gh --version)" && \
    echo "Creating $REPO from $TEMPLATE_REPO" && \
    gh repo create $REPO --template $TEMPLATE_REPO --private && \
    echo "Created $REPO" || exit 1 "Create Repo failed!"

    # Process Merge Template
    git clone $REPO
    cd into $REPO_NAME
    make merge ../$CONTEXT_NAME/Specifications

    # Commit and push changes
    git add *
    git commit "Template Merge Processing Complete"
    git push
```

# History
