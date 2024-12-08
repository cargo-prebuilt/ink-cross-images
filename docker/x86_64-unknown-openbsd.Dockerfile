# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=12-slim
FROM debian:$DEBIAN_VERSION

################################
# This target is nightly ONLY! #
################################

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"

# Versioning
ARG CMAKE_VERSION=3.31.2
ARG OPENSSL_VERSION=openssl-3.4.0
ARG LLVM_VERSION=19
# Bypass openbsd cdn listing a release that is not out. (#36)
ARG OPENBSD_MAJOR=7.6

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=x86_64-unknown-openbsd
ARG OPENBSD_ARCH=amd64

ARG CROSS_TOOLCHAIN=x86_64-unknown-openbsd"$OPENBSD_MAJOR"
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=BSD-x86_64

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
RUN /ink/scripts/setup-clang.sh

# Install openbsd
RUN /ink/scripts/extract-openbsd-sysroot.sh

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT/usr
RUN /ink/scripts/install-openssl-musl.sh

# Cargo prebuilt
RUN /ink/scripts/install-cargo-prebuilt.sh

# Install rust
ARG RUST_VERSION=nightly
RUN /ink/scripts/install-rustup.sh

# Install rust target
ENV RUST_TARGET=$RUST_TARGET
# RUN rustup target add "$RUST_TARGET"

# Create Entrypoint
RUN /ink/scripts/entrypoint.sh

ENV CROSS_TOOLCHAIN_PREFIX=$CROSS_TOOLCHAIN_PREFIX
ENV CROSS_SYSROOT=$CROSS_SYSROOT
ENV CARGO_TARGET_X86_64_UNKNOWN_OPENBSD_LINKER="$CROSS_TOOLCHAIN_PREFIX"clang \
    AR_x86_64_unknown_openbsd="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_x86_64_unknown_openbsd="$CROSS_TOOLCHAIN_PREFIX"clang \
    CXX_x86_64_unknown_openbsd="$CROSS_TOOLCHAIN_PREFIX"clang++ \
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

ENV CARGO_BUILD_TARGET=$RUST_TARGET \
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
