# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=12-slim
ARG ALPINE_VERSION=3
FROM alpine:$ALPINE_VERSION AS rooter

ARG CROSS_TOOLCHAIN=arm-linux-musleabihf
ARG APK_ARCH=armv7

# Script requires bash
RUN apk --no-cache add bash

# Setup sysroot
RUN --mount=type=bind,source=./scripts/extract-alpine-sysroot.sh,target=/run.sh /run.sh

FROM debian:$DEBIAN_VERSION

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"

# Versioning
ARG CMAKE_VERSION=3.31.2
ARG OPENSSL_VERSION=openssl-3.4.0
ARG LLVM_VERSION=19

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=armv7-unknown-linux-musleabihf

ARG CROSS_TOOLCHAIN=arm-linux-musleabihf
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=linux-armv4

ARG LLVM_TARGET=$RUST_TARGET

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
ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER="$CROSS_TOOLCHAIN_PREFIX"clang \
    AR_armv7_unknown_linux_musleabihf="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_armv7_unknown_linux_musleabihf="$CROSS_TOOLCHAIN_PREFIX"clang \
    CXX_armv7_unknown_linux_musleabihf="$CROSS_TOOLCHAIN_PREFIX"clang++ \
    CMAKE_TOOLCHAIN_FILE_armv7_unknown_linux_musleabihf=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_armv7_unknown_linux_musleabihf="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_armv7_unknown_linux_musleabihf=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=arm \
    CROSS_CMAKE_CRT=musl \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -march=armv7-a -mfpu=vfpv3-d16"

ENV CARGO_BUILD_TARGET=$RUST_TARGET \
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
