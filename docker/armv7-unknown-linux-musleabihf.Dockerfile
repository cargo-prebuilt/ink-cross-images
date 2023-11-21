# syntax=docker/dockerfile:1
FROM debian:stable-slim

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL"

# Versioning
ARG RUSTUP_VERSION=1.26.0
ARG CMAKE_VERSION=3.27.7
ARG OPENSSL_VERSION=openssl-3.1.3
ARG LLVM_VERSION=17
ARG MUSL_VERSION=1.2.4

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=armv7-unknown-linux-musleabihf

ARG CROSS_TOOLCHAIN=arm-linux-musleabihf
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=linux-armv4

ARG GCC_PKGS="libgcc-12-dev-armel-cross"

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
ENV PATH=$PATH:$CROSS_SYSROOT/bin
RUN --mount=type=bind,source=./scripts/install-clang.sh,target=/run.sh /run.sh

# Install musl
RUN --mount=type=bind,source=./scripts/install-musl.sh,target=/run.sh /run.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT
RUN --mount=type=bind,source=./scripts/install-openssl-musl.sh,target=/run.sh /run.sh

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
ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER="$CROSS_TOOLCHAIN_PREFIX"clang \
    AR_armv7_unknown_linux_musleabihf="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_armv7_unknown_linux_musleabihf="$CROSS_TOOLCHAIN_PREFIX"clang \
    CXX_armv7_unknown_linux_musleabihf="$CROSS_TOOLCHAIN_PREFIX"clang++ \
    CMAKE_TOOLCHAIN_FILE_armv7_unknown_linux_musleabihf=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_armv7_unknown_linux_musleabihf="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_armv7_unknown_linux_musleabihf=true \
    PKG_CONFIG_PATH="/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/:${PKG_CONFIG_PATH}" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=arm \
    CROSS_CMAKE_CRT=musl \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -march=armv7-a -mfpu=vfpv3-d16"

ENV CARGO_BUILD_TARGET=$RUST_TARGET\
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
