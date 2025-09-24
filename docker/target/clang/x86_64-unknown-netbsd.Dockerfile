# syntax=docker/dockerfile:1
ARG IMG_BASE=ghcr.io/cargo-prebuilt/ink-cross:base-step2-clang-stable
FROM ${IMG_BASE}

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH
ARG CACHE_BUST=cache-v0

# Versioning
ARG OPENSSL_VERSION=openssl-3.5.3
ARG NETBSD_MAJOR=10

ARG RUST_TARGET=x86_64-unknown-netbsd
ARG NETBSD_ARCH=amd64

ARG CROSS_TOOLCHAIN=x86_64-unknown-netbsd${NETBSD_MAJOR}
ARG CROSS_TOOLCHAIN_PREFIX=${CROSS_TOOLCHAIN}-
ARG CROSS_SYSROOT=/usr/${CROSS_TOOLCHAIN}

ARG OPENSSL_COMBO=BSD-x86_64

ARG LLVM_TARGET=$RUST_TARGET

# Copy required scripts and Dockerfile
COPY ./scripts/target/clang /ink/scripts/target/clang
COPY ./scripts/target/bsd/netbsd /ink/scripts/target/bsd/netbsd
COPY ./docker/target/clang/$RUST_TARGET.Dockerfile /ink/dockerfiles/

# Setup clang
ENV PATH=$PATH:$CROSS_SYSROOT/usr/bin
RUN /ink/scripts/target/clang/setup-clang.sh

# Install netbsd
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/netbsd",sharing=locked \
    /ink/scripts/target/bsd/netbsd/extract-netbsd-sysroot.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl",sharing=locked \
    /ink/scripts/target/clang/install-openssl-clang.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
RUN rustup target add "$RUST_TARGET"

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_X86_64_UNKNOWN_NETBSD_LINKER=${CROSS_TOOLCHAIN_PREFIX}clang \
    CARGO_BUILD_TARGET=$RUST_TARGET \
    AR_x86_64_unknown_netbsd=${CROSS_TOOLCHAIN_PREFIX}ar \
    CC_x86_64_unknown_netbsd=${CROSS_TOOLCHAIN_PREFIX}clang \
    CXX_x86_64_unknown_netbsd=${CROSS_TOOLCHAIN_PREFIX}clang++ \
    CMAKE_TOOLCHAIN_FILE_x86_64_unknown_netbsd=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_netbsd="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_x86_64_unknown_netbsd=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CROSS_CMAKE_SYSTEM_NAME=NetBSD \
    CROSS_CMAKE_SYSTEM_PROCESSOR=amd64 \
    CROSS_CMAKE_CRT=netbsd \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64"
