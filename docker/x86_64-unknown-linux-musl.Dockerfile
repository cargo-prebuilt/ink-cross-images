# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=12-slim
ARG ALPINE_VERSION=edge
FROM alpine:$ALPINE_VERSION as rooter

ARG CROSS_TOOLCHAIN=x86_64-linux-musl
ARG APK_ARCH=x86_64

# Script requires bash
RUN apk --no-cache add bash

# Setup sysroot
RUN --mount=type=bind,source=./scripts/extract-alpine-sysroot.sh,target=/run.sh /run.sh

FROM debian:$DEBIAN_VERSION

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL"

# Versioning
ARG CMAKE_VERSION=3.29.1
ARG OPENSSL_VERSION=openssl-3.3.0
ARG LLVM_VERSION=18

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=x86_64-unknown-linux-musl

ARG CROSS_TOOLCHAIN=x86_64-linux-musl
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=linux-x86_64

ARG LLVM_TARGET=$RUST_TARGET

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# Upgrade and install apt packages
RUN --mount=type=bind,source=./scripts/manage-apt.sh,target=/run.sh /run.sh

# Install cmake
RUN --mount=type=bind,source=./scripts/install-cmake.sh,target=/run.sh /run.sh
COPY ./cmake/toolchain-clang.cmake /opt/toolchain.cmake

# Install clang
ENV PATH=$PATH:$CROSS_SYSROOT/usr/bin
RUN --mount=type=bind,source=./scripts/install-clang.sh,target=/run.sh /run.sh

# Install sysroot (musl + libstdc++ + libgcc)
COPY --from=rooter /opt/export/ $CROSS_SYSROOT/usr
RUN --mount=type=bind,source=./scripts/setup-clang.sh,target=/run.sh /run.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN --mount=type=bind,source=./scripts/install-openssl-clang.sh,target=/run.sh /run.sh

# Cargo prebuilt
RUN --mount=type=bind,source=./scripts/install-cargo-prebuilt.sh,target=/run.sh /run.sh

# Install rust
ARG RUST_VERSION=stable
RUN --mount=type=bind,source=./scripts/install-rustup.sh,target=/run.sh /run.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
RUN rustup target add "$RUST_TARGET"

# Create Entrypoint
RUN --mount=type=bind,source=./scripts/entrypoint.sh,target=/run.sh /run.sh

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER="$CROSS_TOOLCHAIN_PREFIX"clang \
    AR_x86_64_unknown_linux_musl="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_x86_64_unknown_linux_musl="$CROSS_TOOLCHAIN_PREFIX"clang \
    CXX_x86_64_unknown_linux_musl="$CROSS_TOOLCHAIN_PREFIX"clang++ \
    CMAKE_TOOLCHAIN_FILE_x86_64_unknown_linux_musl=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_linux_musl="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_x86_64_unknown_linux_musl=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/:${PKG_CONFIG_PATH}" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=x86_64 \
    CROSS_CMAKE_CRT=musl \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64"

ENV CARGO_BUILD_TARGET=$RUST_TARGET \
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
