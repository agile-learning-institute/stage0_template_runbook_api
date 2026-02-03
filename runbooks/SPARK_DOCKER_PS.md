# Check Containers on SPARK

This runbook just does a ``docker ps`` on the Spark server

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
  docker ps
  pwd
EOF
```

# History

### 2026-01-27T18:38:26.691Z | Exit Code: 0

**Stdout:**
```
CONTAINER ID   IMAGE                                                              COMMAND                  CREATED          STATUS                    PORTS                                                           NAMES
d459e8f6d400   ghcr.io/agile-crafts-people/template_spa:latest                    "/docker-entrypoint.…"   3 minutes ago    Up 3 minutes              0.0.0.0:8185->80/tcp, [::]:8185->80/tcp                         dev-template_spa-1
d40424ab26dc   ghcr.io/agile-learning-institute/mongodb_configurator_spa:latest   "/docker-entrypoint.…"   3 minutes ago    Up 3 minutes              80/tcp, 8082/tcp, 0.0.0.0:8181->8181/tcp, [::]:8181->8181/tcp   dev-mongodb_spa-1
6cafde7489a2   ghcr.io/agile-crafts-people/template_api:latest                    "/bin/sh -c 'exec gu…"   3 minutes ago    Up 3 minutes              0.0.0.0:8184->8184/tcp, [::]:8184->8184/tcp                     dev-template_api-1
57e7d1e01b14   ghcr.io/agile-crafts-people/mongodb_api:latest                     "gunicorn --bind 0.0…"   3 minutes ago    Up 3 minutes (healthy)    0.0.0.0:8180->8081/tcp, [::]:8180->8081/tcp                     dev-mongodb_api-1
8233fe2110aa   mongo:7.0.5                                                        "docker-entrypoint.s…"   3 minutes ago    Up 3 minutes (healthy)    0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp                 dev-mongodb-1
a7166adb6451   ghcr.io/agile-learning-institute/stage0_runbook_spa:latest         "/docker-entrypoint.…"   5 minutes ago    Up 5 minutes              0.0.0.0:8183->80/tcp, [::]:8183->80/tcp                         runbook_spa
a74de9ea5c47   ghcr.io/agile-crafts-people/runbook_api:latest                     "/bin/sh -c 'exec gu…"   5 minutes ago    Up 5 minutes              8083/tcp, 0.0.0.0:8182->8182/tcp, [::]:8182->8182/tcp           runbook_api
899ffeee5c98   ghcr.io/open-webui/open-webui:ollama                               "bash start.sh"          54 minutes ago   Up 54 minutes (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp                     open-webui
a56f8cb5372f   ollama/ollama                                                      "/bin/ollama serve"      54 minutes ago   Up 54 minutes             0.0.0.0:11434->11434/tcp, [::]:11434->11434/tcp                 ollama
/home/sre

```

**Stderr:**
```
Warning: Permanently added 'spark-478a.tailb0d293.ts.net' (ED25519) to the list of known hosts.

```
