# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=12-slim
ARG ALPINE_VERSION=3
FROM alpine:$ALPINE_VERSION AS rooter

ARG CROSS_TOOLCHAIN=riscv64-linux-musl
ARG APK_ARCH=riscv64

# Script requires bash
RUN apk --no-cache add bash

# Setup sysroot
RUN --mount=type=bind,source=./scripts/extract-alpine-sysroot.sh,target=/run.sh /run.sh

FROM debian:$DEBIAN_VERSION

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"

# Versioning
ARG CMAKE_VERSION=3.30.4
ARG OPENSSL_VERSION=openssl-3.3.2
ARG LLVM_VERSION=19

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=riscv64gc-unknown-linux-musl

ARG CROSS_TOOLCHAIN=riscv64-linux-musl
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=linux64-riscv64

ARG LLVM_TARGET=riscv64-unknown-linux-musl

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# For auditing
COPY ./docker/"$RUST_TARGET".Dockerfile /ink/
COPY ./scripts /ink/scripts/

# Upgrade and install apt packages
RUN /ink/scripts/manage-apt.sh

# Install cmake
RUN /ink/scripts/install-cmake.sh
COPY ./cmake/toolchain-clang.cmake /opt/toolchain.cmake

# Install clang
ENV PATH=$PATH:$CROSS_SYSROOT/usr/bin
RUN /ink/scripts/install-clang.sh

# Install sysroot (musl + libstdc++ + libgcc)
COPY --from=rooter /opt/export/ $CROSS_SYSROOT/usr
RUN /ink/scripts/setup-clang.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN /ink/scripts/install-openssl-clang.sh

# Cargo prebuilt
RUN /ink/scripts/install-cargo-prebuilt.sh

# Install rust
ARG RUST_VERSION=stable
RUN /ink/scripts/install-rustup.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
RUN rustup target add "$RUST_TARGET"

# Create Entrypoint
RUN /ink/scripts/entrypoint.sh

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_RISCV64GC_UNKNOWN_LINUX_MUSL_LINKER="$CROSS_TOOLCHAIN_PREFIX"clang \
    AR_riscv64gc_unknown_linux_musl="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_riscv64gc_unknown_linux_musl="$CROSS_TOOLCHAIN_PREFIX"clang \
    CXX_riscv64gc_unknown_linux_musl="$CROSS_TOOLCHAIN_PREFIX"clang++ \
    CMAKE_TOOLCHAIN_FILE_riscv64gc_unknown_linux_musl=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_riscv64gc_unknown_linux_musl="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_riscv64gc_unknown_linux_musl=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=riscv64 \
    CROSS_CMAKE_CRT=musl \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC"

ENV CARGO_BUILD_TARGET=$RUST_TARGET \
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
