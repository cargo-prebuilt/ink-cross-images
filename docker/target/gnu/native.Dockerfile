# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step1-stable
FROM ${IMG_BASE}

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH
ARG CACHE_BUST=cache-v0

# Versioning
ARG OPENSSL_VERSION=openssl-3.5.0

ARG RUST_TARGET=native

ARG CROSS_TOOLCHAIN=""
ARG CROSS_TOOLCHAIN_PREFIX=""
ARG CROSS_SYSROOT=/usr/local

ARG GCC_PKGS="g++ libc6-dev"

# Copy required scripts and Dockerfile
COPY ./scripts/target/gnu /ink/scripts/target/gnu
COPY ./docker/target/gnu/$RUST_TARGET.Dockerfile /ink/dockerfiles/

# Install gcc packages
RUN /ink/scripts/target/gnu/manage-apt.sh

# Openssl
SHELL [ "/bin/bash", "-c" ]
ENV OPENSSL_DIR=$CROSS_SYSROOT
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl",sharing=locked <<EOF
    #!/bin/bash

    set -euxo pipefail

    case "$TARGETARCH" in
    amd64)
        export OPENSSL_COMBO="linux-x86_64"
        ;;
    arm64)
        export OPENSSL_COMBO="linux-aarch64"
        ;;
    *)
        echo "Unsupported Arch: $TARGETARCH" && exit 1
        ;;
    esac

    /ink/scripts/target/gnu/install-openssl-gnu.sh
EOF
