# Create GitHub Package

This runbook creates a GitHub Container Registry Package by building a HelloWorld image using [this Dockerfile](./CreatePackage.dockerfile), labeling it to connect to a source code repo, and pushes this new image to ghcr.

# Environment Requirements
```yaml
GITHUB_TOKEN: A github classic token with package:write Privileges
ORG: Github Organization i.e. agile-crafts-people
REPO: Package and Repo Name 
```

# File System Requirements
```yaml
Input:
- ./CreatePackage.dockerfile
```

# Required Claims
```yaml
roles: sre
```

# Script
```sh
echo "Starting create package for ${ORG}/${REPO}" && \
echo $GITHUB_TOKEN | docker login ghcr.io -u agile-crafts-people --password-stdin && \
echo "Logged In" && \
DOCKER_BUILDKIT=0 docker build -f CreatePackage.dockerfile \
  --build-arg ORG=${ORG} --build-arg REPO=${REPO} \
  -t ghcr.io/${ORG}/${REPO}:latest . && \
echo "Container Image Created" && \
docker push ghcr.io/${ORG}/${REPO}:latest && \
echo "Package Pushed"
```

# History
