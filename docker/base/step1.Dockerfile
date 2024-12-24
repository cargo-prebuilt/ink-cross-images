# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step0
FROM ${IMG_BASE}

# Build Args
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH

# Versioning
ARG RUST_VERSION=stable
ENV RUST_VERSION=${RUST_VERSION}

# Copy required scripts and Dockerfile
COPY ./scripts/base/step1 /ink/scripts/base/step1
COPY ./docker/base/step1.Dockerfile /ink/dockerfiles

# Install rust toolchain
RUN /ink/scripts/base/step1/install-rustup.sh

# Create Entrypoint
RUN /ink/scripts/base/step1/entrypoint.sh
