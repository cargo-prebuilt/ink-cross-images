# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step2-clang-nightly
FROM ${IMG_BASE}

################################
# This target is nightly ONLY! #
################################

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH
ARG CACHE_BUST=cache-v0

# Versioning
ARG OPENSSL_VERSION=openssl-3.6.0
ARG FREEBSD_MAJOR=13

ARG RUST_TARGET=aarch64-unknown-freebsd
ARG FREEBSD_ARCH=arm64

ARG CROSS_TOOLCHAIN=aarch64-unknown-freebsd${FREEBSD_MAJOR}
ARG CROSS_TOOLCHAIN_PREFIX=${CROSS_TOOLCHAIN}-
ARG CROSS_SYSROOT=/usr/${CROSS_TOOLCHAIN}

ARG OPENSSL_COMBO=BSD-generic64

ARG LLVM_TARGET=$RUST_TARGET

# Copy required scripts and Dockerfile
COPY ./scripts/target/clang /ink/scripts/target/clang
COPY ./scripts/target/bsd/freebsd /ink/scripts/target/bsd/freebsd
COPY ./docker/target/clang/$RUST_TARGET.Dockerfile /ink/dockerfiles/

# Setup clang
ENV PATH=$PATH:$CROSS_SYSROOT/usr/bin
RUN /ink/scripts/target/clang/setup-clang.sh

# Install freebsd
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/freebsd",sharing=locked \
    /ink/scripts/target/bsd/freebsd/extract-freebsd-sysroot.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl",sharing=locked \
    /ink/scripts/target/clang/install-openssl-clang.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
# RUN rustup target add "$RUST_TARGET"

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_AARCH64_UNKNOWN_FREEBSD_LINKER="${CROSS_TOOLCHAIN_PREFIX}clang" \
    CARGO_BUILD_TARGET=$RUST_TARGET \
    AR_aarch64_unknown_freebsd="${CROSS_TOOLCHAIN_PREFIX}ar" \
    CC_aarch64_unknown_freebsd="${CROSS_TOOLCHAIN_PREFIX}clang" \
    CXX_aarch64_unknown_freebsd="${CROSS_TOOLCHAIN_PREFIX}clang++" \
    CMAKE_TOOLCHAIN_FILE_aarch64_unknown_freebsd=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_freebsd="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_aarch64_unknown_freebsd=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CROSS_CMAKE_SYSTEM_NAME=FreeBSD \
    CROSS_CMAKE_SYSTEM_PROCESSOR=arm64 \
    CROSS_CMAKE_CRT=freebsd \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64"
