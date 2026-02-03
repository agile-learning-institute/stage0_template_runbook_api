# Create GitHub Repo

This runbook creates a GitHub Repo from the provided Repo Template. 

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with ✅ repo Privileges
REPO: The full name of the repo to be created (org/repo)
TEMPLATE_REPO: The full name of the Template Repo (org/repo)
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
echo "Using GitHub CLI Version $(gh --version)" && \
echo "Creating $REPO from $TEMPLATE_REPO"
gh repo create $REPO --template $TEMPLATE_REPO --private && \
echo "Created $REPO"
```

# History

### 2026-01-12T23:19:18.617Z | Exit Code: 0

**Stdout:**
```
Using GitHub CLI Version gh version 2.83.2 (2025-12-10)
https://github.com/cli/cli/releases/tag/v2.83.2
Creating agile-crafts-people/test from agile-crafts-people/template_flask_mongo
https://github.com/agile-crafts-people/test
Created 

```

**Stderr:**
```
Flag --confirm has been deprecated, Pass any argument to skip confirmation prompt
/tmp/runbook-exec-f3740c6d-5s_lcwbu/temp.zsh:5: command not found: REPO

```

### 2026-01-12T23:21:50.601Z | Exit Code: 0

**Stdout:**
```
Using GitHub CLI Version gh version 2.83.2 (2025-12-10)
https://github.com/cli/cli/releases/tag/v2.83.2
Creating agile-crafts-people/test from agile-crafts-people/template_flask_mongo
https://github.com/agile-crafts-people/test
Created 

```

**Stderr:**
```
/tmp/runbook-exec-77f92d7e-1beox79n/temp.zsh:5: command not found: REPO

```

### 2026-01-12T23:22:45.103Z | Exit Code: 0

**Stdout:**
```
Using GitHub CLI Version gh version 2.83.2 (2025-12-10)
https://github.com/cli/cli/releases/tag/v2.83.2
Creating agile-crafts-people/test2 from agile-crafts-people/template_flask_mongo
https://github.com/agile-crafts-people/test2
Created agile-crafts-people/test2

```


### 2026-01-12T23:24:36.398Z | Exit Code: 403

**Error:**
```
RBAC Failure: Access denied for user dev-user-1. RBAC check failed for execute. Missing or invalid claims: roles=developer, admin (required: sre)
```

### 2026-01-12T23:25:35.878Z | Exit Code: 0

**Stdout:**
```
Using GitHub CLI Version gh version 2.83.2 (2025-12-10)
https://github.com/cli/cli/releases/tag/v2.83.2
Creating agile-crafts-people/test4 from agile-crafts-people/template_flask_mongo
https://github.com/agile-crafts-people/test4
Created agile-crafts-people/test4

```

