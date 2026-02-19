# Verify Prerequisites

This runbook verifies that all required build tools are installed and reports their versions. Use it to confirm the runbook execution environment is correctly configured before running more complex runbooks like CreateService or CreateProduct.

# Environment Requirements
```yaml
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

echo "=== Verifying installed tools ==="

echo ""
echo "--- Build tools ---"
echo -n "make:    "; make --version | head -1
echo -n "node:    "; node --version
echo -n "npm:     "; npm --version
echo -n "vite:    "; vite --version

echo ""
echo "--- Python tools ---"
echo -n "python3: "; python3 --version
echo -n "pipenv:  "; pipenv --version

echo ""
echo "--- Container tools ---"
echo -n "docker:  "; docker --version
echo -n "buildx:  "; docker buildx version

echo ""
echo "--- GitHub & Git ---"
echo -n "gh:      "; gh --version | head -1
echo -n "git:     "; git --version

echo ""
echo "--- Utilities ---"
echo -n "jq:      "; jq --version
echo -n "yq:      "; yq --version
echo -n "curl:    "; curl --version | head -1
echo -n "ssh:     "; ssh -V 2>&1

echo ""
echo "=== All prerequisites verified ==="
```

# History

### 2026-02-14T01:17:15.049Z | Exit Code: 0

**Stdout:**
```
=== Verifying installed tools ===

--- Build tools ---
make:    GNU Make 4.4.1
node:    v20.20.0
npm:     10.8.2

--- Python tools ---
python3: Python 3.12.12
pipenv:  pipenv, version 2026.0.3

--- Container tools ---
docker:  Docker version 29.2.1, build a5c7197
buildx:  github.com/docker/buildx v0.12.1 30feaa1a915b869ebc2eea6328624b49facd4bfb

--- GitHub & Git ---
gh:      gh version 2.86.0 (2026-01-21)
git:     git version 2.47.3

--- Utilities ---
jq:      jq-1.7
yq:      yq (https://github.com/mikefarah/yq/) version v4.52.2
curl:    curl 8.14.1 (aarch64-unknown-linux-gnu) libcurl/8.14.1 OpenSSL/3.5.4 zlib/1.3.1 brotli/1.1.0 zstd/1.5.7 libidn2/2.3.8 libpsl/0.21.2 libssh2/1.11.1 nghttp2/1.64.0 nghttp3/1.8.0 librtmp/2.3 OpenLDAP/2.6.10
ssh:     OpenSSH_10.0p2 Debian-7, OpenSSL 3.5.4 30 Sep 2025

=== All prerequisites verified ===

```


### 2026-02-14T01:29:24.685Z | Exit Code: 0

**Stdout:**
```
=== Verifying installed tools ===

--- Build tools ---
make:    GNU Make 4.4.1
node:    v20.20.0
npm:     10.8.2
vite:    vite/7.3.1 linux-arm64 node-v20.20.0

--- Python tools ---
python3: Python 3.12.12
pipenv:  pipenv, version 2026.0.3

--- Container tools ---
docker:  Docker version 29.2.1, build a5c7197
buildx:  github.com/docker/buildx v0.12.1 30feaa1a915b869ebc2eea6328624b49facd4bfb

--- GitHub & Git ---
gh:      gh version 2.86.0 (2026-01-21)
git:     git version 2.47.3

--- Utilities ---
jq:      jq-1.7
yq:      yq (https://github.com/mikefarah/yq/) version v4.52.2
curl:    curl 8.14.1 (aarch64-unknown-linux-gnu) libcurl/8.14.1 OpenSSL/3.5.4 zlib/1.3.1 brotli/1.1.0 zstd/1.5.7 libidn2/2.3.8 libpsl/0.21.2 libssh2/1.11.1 nghttp2/1.64.0 nghttp3/1.8.0 librtmp/2.3 OpenLDAP/2.6.10
ssh:     OpenSSH_10.0p2 Debian-7, OpenSSL 3.5.4 30 Sep 2025

=== All prerequisites verified ===

```

