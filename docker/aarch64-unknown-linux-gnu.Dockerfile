# syntax=docker/dockerfile:1
FROM debian:stable-slim

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL"

# Versioning
ARG CMAKE_VERSION=3.28.3
ARG OPENSSL_VERSION=openssl-3.2.1

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=aarch64-unknown-linux-gnu

ARG CROSS_TOOLCHAIN=aarch64-linux-gnu
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=linux-aarch64

ARG GCC_PKGS="g++-aarch64-linux-gnu libc6-dev-arm64-cross"

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# Upgrade and install apt packages
RUN --mount=type=bind,source=./scripts/manage-apt.sh,target=/run.sh /run.sh

# Install cmake
RUN --mount=type=bind,source=./scripts/install-cmake.sh,target=/run.sh /run.sh
COPY ./cmake/toolchain-gcc.cmake /opt/toolchain.cmake

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT
RUN --mount=type=bind,source=./scripts/install-openssl-gnu.sh,target=/run.sh /run.sh

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
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="$CROSS_TOOLCHAIN_PREFIX"gcc \
    AR_aarch64_unknown_linux_gnu="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_aarch64_unknown_linux_gnu="$CROSS_TOOLCHAIN_PREFIX"gcc \
    CXX_aarch64_unknown_linux_gnu="$CROSS_TOOLCHAIN_PREFIX"g++ \
    CMAKE_TOOLCHAIN_FILE_aarch64_unknown_linux_gnu=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_linux_gnu="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_aarch64_unknown_linux_gnu=true \
    PKG_CONFIG_PATH="/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/:${PKG_CONFIG_PATH}" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=aarch64 \
    CROSS_CMAKE_CRT=gnu \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC"

ENV CARGO_BUILD_TARGET=$RUST_TARGET\
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
