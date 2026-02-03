# Deploy :latest CreatorDashboard to SPARK

This runbook restarts the Spark hosted DEV environment after pulling the latest docker-compose.yaml container images:latest from GitHub. You will need to configure ``ssh sre@spark-478a.tailb0d293.ts.net`` to run this script, your ~/.ssh keys are used by the ``de`` script when starting the service. 

# Environment Requirements
```yaml
SSH_KEY: The SSH private key content for key-based authentication (~/.ssh/id_ed25519)
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
#!/bin/zsh
set -euo pipefail

# SSH connection configuration from environment variables
SSH_HOST=""spark-478a.tailb0d293.ts.net""
SSH_USER="sre"
SSH_PORT="22"

# Create temporary key file with secure permissions
KEY_FILE=$(mktemp)
echo "$SSH_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"
# Ensure cleanup on exit
trap "rm -f $KEY_FILE" EXIT

# Configure SSH options
SSH_OPTS=(-i "$KEY_FILE" -p "$SSH_PORT" -o StrictHostKeyChecking=no)

# SSH and use docker compose to deploy latest code
ssh "${SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" "bash -s" <<'EOF'
  cd ~/CreatorDashboard
  git pull
  cd ~/CreatorDashboard/DeveloperEdition/sre_resources/DEV
  docker compose down --remove-orphans 
  docker compose pull
  export JWT_SECRET=$(date +%s)
  docker compose up -d
EOF
```

# History
