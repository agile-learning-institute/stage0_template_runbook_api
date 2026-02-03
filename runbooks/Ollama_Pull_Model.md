# Install Ollama Model on SPARK

# Environment Requirements
```yaml
PULL_MODEL_NAME: The Ollama Model Name 
```

# File System Requirements
```yaml
Input:
```

# Required Claims
```yaml
sre
```

# Script
```sh
#! /bin/zsh
echo "Running"
echo "Pulling model: $PULL_MODEL_NAME"
curl -X POST http://spark-478a.tailb0d293.ts.net:11434/api/pull -d "{\"model\":\"${PULL_MODEL_NAME}\"}" | jq

```

# History
