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
ARG OPENSSL_VERSION=openssl-3.5.0
# Bypass openbsd cdn listing a release that is not out. (#36)
ARG OPENBSD_MAJOR=7.6

ARG RUST_TARGET=x86_64-unknown-openbsd
ARG OPENBSD_ARCH=amd64

ARG CROSS_TOOLCHAIN=x86_64-unknown-openbsd${OPENBSD_MAJOR}
ARG CROSS_TOOLCHAIN_PREFIX=${CROSS_TOOLCHAIN}-
ARG CROSS_SYSROOT=/usr/${CROSS_TOOLCHAIN}

ARG OPENSSL_COMBO=BSD-x86_64

ARG LLVM_TARGET=$RUST_TARGET

# Copy required scripts and Dockerfile
COPY ./scripts/target/clang /ink/scripts/target/clang
COPY ./scripts/target/bsd/openbsd /ink/scripts/target/bsd/openbsd
COPY ./scripts/target/musl /ink/scripts/target/musl
COPY ./docker/target/clang/$RUST_TARGET.Dockerfile /ink/dockerfiles/

# Setup clang
ENV PATH=$PATH:$CROSS_SYSROOT/usr/bin
RUN /ink/scripts/target/clang/setup-clang.sh

# Install openbsd
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openbsd",sharing=locked \
    /ink/scripts/target/bsd/openbsd/extract-openbsd-sysroot.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN --mount=type=cache,target="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl",sharing=locked \
    /ink/scripts/target/musl/install-openssl-musl.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
# RUN rustup target add "$RUST_TARGET"

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_X86_64_UNKNOWN_OPENBSD_LINKER=${CROSS_TOOLCHAIN_PREFIX}clang \
    CARGO_BUILD_TARGET=$RUST_TARGET \
    AR_x86_64_unknown_openbsd="${CROSS_TOOLCHAIN_PREFIX}ar" \
    CC_x86_64_unknown_openbsd="${CROSS_TOOLCHAIN_PREFIX}clang" \
    CXX_x86_64_unknown_openbsd="${CROSS_TOOLCHAIN_PREFIX}clang++" \
    CMAKE_TOOLCHAIN_FILE_x86_64_unknown_openbsd=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_openbsd="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_x86_64_unknown_openbsd=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/usr/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CROSS_CMAKE_SYSTEM_NAME=OpenBSD \
    CROSS_CMAKE_SYSTEM_PROCESSOR=amd64 \
    CROSS_CMAKE_CRT=openbsd \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64"
