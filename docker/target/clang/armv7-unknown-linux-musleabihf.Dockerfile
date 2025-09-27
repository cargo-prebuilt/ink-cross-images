# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step2-clang-stable
ARG ALPINE_VERSION=3
FROM alpine:$ALPINE_VERSION AS rooter

ARG CROSS_TOOLCHAIN=arm-linux-musleabihf
ARG APK_ARCH=armv7
ARG CACHE_BUST=cache-v0
ARG ALPINE_VERSION=3

# Script requires bash
RUN apk --no-cache add bash

# Setup sysroot
COPY ./scripts/target/musl /ink/scripts/target/musl
RUN --mount=type=cache,target="/opt/${CROSS_TOOLCHAIN}/extract",sharing=locked \
    /ink/scripts/target/musl/extract-alpine-sysroot.sh

FROM ${IMG_BASE}

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH
ARG CACHE_BUST=cache-v0

# Versioning
ARG OPENSSL_VERSION=openssl-3.5.3

ARG RUST_TARGET=armv7-unknown-linux-musleabihf

ARG CROSS_TOOLCHAIN=arm-linux-musleabihf
ARG CROSS_TOOLCHAIN_PREFIX=${CROSS_TOOLCHAIN}-
ARG CROSS_SYSROOT=/usr/${CROSS_TOOLCHAIN}

ARG OPENSSL_COMBO=linux-armv4

ARG LLVM_TARGET=$RUST_TARGET

# Copy required scripts and Dockerfile
COPY ./scripts/target/clang /ink/scripts/target/clang
COPY ./scripts/target/musl /ink/scripts/target/musl
COPY ./docker/target/clang/$RUST_TARGET.Dockerfile /ink/dockerfiles/

# Install sysroot (musl + libstdc++ + libgcc)
COPY --from=rooter /opt/export $CROSS_SYSROOT/usr

# Setup clang
ENV PATH=$PATH:$CROSS_SYSROOT/usr/bin
RUN /ink/scripts/target/clang/setup-clang.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl",sharing=locked \
    /ink/scripts/target/clang/install-openssl-clang.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
RUN rustup target add "$RUST_TARGET"

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=${CROSS_TOOLCHAIN_PREFIX}clang \
    CARGO_BUILD_TARGET=$RUST_TARGET \
    AR_armv7_unknown_linux_musleabihf=${CROSS_TOOLCHAIN_PREFIX}ar \
    CC_armv7_unknown_linux_musleabihf=${CROSS_TOOLCHAIN_PREFIX}clang \
    CXX_armv7_unknown_linux_musleabihf=${CROSS_TOOLCHAIN_PREFIX}clang++ \
    CMAKE_TOOLCHAIN_FILE_armv7_unknown_linux_musleabihf=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_armv7_unknown_linux_musleabihf="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_armv7_unknown_linux_musleabihf=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=arm \
    CROSS_CMAKE_CRT=musl \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -march=armv7-a -mfpu=vfpv3-d16"
