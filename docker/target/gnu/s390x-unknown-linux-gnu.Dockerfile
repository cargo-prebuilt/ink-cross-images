# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step1-stable
FROM ${IMG_BASE}

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH
ARG CACHE_BUST=cache-v0

# Versioning
ARG OPENSSL_VERSION=openssl-3.5.0

ARG RUST_TARGET=s390x-unknown-linux-gnu

ARG CROSS_TOOLCHAIN=s390x-linux-gnu
ARG CROSS_TOOLCHAIN_PREFIX=${CROSS_TOOLCHAIN}-
ARG CROSS_SYSROOT=/usr/${CROSS_TOOLCHAIN}

ARG OPENSSL_COMBO=linux64-s390x

ARG GCC_PKGS="g++-s390x-linux-gnu libc6-dev-s390x-cross"

# Copy required scripts and Dockerfile
COPY ./scripts/target/gnu /ink/scripts/target/gnu
COPY ./docker/target/gnu/$RUST_TARGET.Dockerfile /ink/dockerfiles/

# Install gcc packages
RUN /ink/scripts/target/gnu/manage-apt.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl",sharing=locked \
    /ink/scripts/target/gnu/install-openssl-gnu.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
RUN rustup target add "$RUST_TARGET"

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_S390X_UNKNOWN_LINUX_GNU_LINKER=${CROSS_TOOLCHAIN_PREFIX}gcc \
    CARGO_BUILD_TARGET=$RUST_TARGET \
    AR_s390x_unknown_linux_gnu=${CROSS_TOOLCHAIN_PREFIX}ar \
    CC_s390x_unknown_linux_gnu=${CROSS_TOOLCHAIN_PREFIX}gcc \
    CXX_s390x_unknown_linux_gnu=${CROSS_TOOLCHAIN_PREFIX}g++ \
    CMAKE_TOOLCHAIN_FILE_s390x_unknown_linux_gnu=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_s390x_unknown_linux_gnu="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_s390x_unknown_linux_gnu=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=s390x \
    CROSS_CMAKE_CRT=gnu \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC"
