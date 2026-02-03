# Deploy :latest Runbook to SPARK

This runbook updates the Spark hosted Runbook environment. You will need to configure ``ssh sre@spark-478a.tailb0d293.ts.net`` to run this script, your ~/.ssh keys are used by the ``de`` script when starting the service. 

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
  cd ~/CreatorDashboard/DeveloperEdition/sre_resources/RUNBOOK
  
  export SSH_KEY=$(cat ~/.ssh/id_ed25519)
  export JWT_SECRET=$(date +%s)
  nohup bash -c '
    docker compose down --remove-orphans && \
    echo "images down" && \
    docker compose pull && \
    echo "images pulled" && \
    docker compose up -d --force-recreate && \
    echo "images up"' > ./nohup.out 2>&1 &
EOF
```

# History
