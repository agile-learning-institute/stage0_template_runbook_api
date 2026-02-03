FROM hello-world:latest

ARG REPO
ARG ORG
LABEL org.opencontainers.image.source="https://github.com/${ORG}/${REPO}"

