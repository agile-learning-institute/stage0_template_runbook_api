FROM ghcr.io/agile-learning-institute/stage0_runbook_api:latest
LABEL org.opencontainers.image.source="{{org.git_host}}/{{org.git_org}}/{{info.slug}}_runbook_api"

##################################
# Install all dependencies (cached unless base image changes)
# This layer will be reused when only runbooks change
##################################
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg && \
    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    # Install Docker CLI
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Update and install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gh \
        docker-ce-cli \
        openssh-client \
        jq && \
    # Install Docker Buildx
    mkdir -p /root/.docker/cli-plugins && \
    curl -SL https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-$(dpkg --print-architecture) -o /root/.docker/cli-plugins/docker-buildx && \
    chmod +x /root/.docker/cli-plugins/docker-buildx && \
    # Install yq
    curl -SL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture) -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    # Cleanup and verify
    rm -rf /var/lib/apt/lists/* && \
    gh --version && \
    docker --version && \
    docker buildx version && \
    yq --version && \
    jq --version

##################################
# Create runbooks directory (cached unless dependencies change)
##################################
RUN mkdir -p /opt/stage0/runner/runbooks

##################################
# Set working directory (cached unless directory structure changes)
##################################
WORKDIR /opt/stage0/runner

##################################
# Copy runbooks LAST (most frequently changing layer)
# This is the only layer that rebuilds when runbooks change
##################################
COPY ./runbooks/ /opt/stage0/runner/runbooks/
