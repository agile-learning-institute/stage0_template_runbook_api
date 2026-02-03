# Deploy :latest Ollama to SPARK
This script upgrades the Ollama services on ``spark-478a.tailb0d293.ts.net``

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

# SSH and use docker to pull and deploy the latest
ssh "${SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" "bash -s" <<'EOF'
  set -euo pipefail
  docker stop ollama 
  docker rm ollama 
  docker pull ollama/ollama:latest 
  docker run -d  -p 11434:11434 --gpus=all \
    -v open-webui-ollama:/root/.ollama \
    --name ollama ollama/ollama 
  docker image prune -f
  docker ps
EOF
```

# History
 