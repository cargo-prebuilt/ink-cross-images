# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step1-stable
FROM ${IMG_BASE}

# Build Args
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH

# Versioning
ARG LLVM_VERSION=19
ENV LLVM_VERSION=${LLVM_VERSION}

# Copy required scripts and Dockerfile
COPY ./scripts/base/step2-clang /ink/scripts/base/step2-clang
COPY ./docker/base/step2-clang.Dockerfile /ink/dockerfiles/

# Override gnu cmake toolchain
COPY ./cmake/toolchain-clang.cmake /opt/toolchain.cmake

# Install clang
RUN /ink/scripts/base/step2-clang/install-clang.sh
