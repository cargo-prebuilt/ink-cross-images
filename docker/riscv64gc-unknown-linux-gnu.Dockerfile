# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=12-slim
FROM debian:$DEBIAN_VERSION

# Build CMDS
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"

# Versioning
ARG CMAKE_VERSION=3.31.2
ARG OPENSSL_VERSION=openssl-3.4.0

# Do not set
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ARG RUST_TARGET=riscv64gc-unknown-linux-gnu

ARG CROSS_TOOLCHAIN=riscv64-linux-gnu
ARG CROSS_TOOLCHAIN_PREFIX="$CROSS_TOOLCHAIN"-
ARG CROSS_SYSROOT=/usr/"$CROSS_TOOLCHAIN"

ARG OPENSSL_COMBO=linux64-riscv64

ARG GCC_PKGS="g++-riscv64-linux-gnu libc6-dev-riscv64-cross"

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
COPY ./cmake/toolchain-gcc.cmake /opt/toolchain.cmake

# Openssl
ENV OPENSSL_DIR=$CROSS_SYSROOT
RUN /ink/scripts/install-openssl-gnu.sh

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
ENV CARGO_TARGET_RISCV64GC_UNKNOWN_LINUX_GNU_LINKER="$CROSS_TOOLCHAIN_PREFIX"gcc \
    AR_riscv64gc_unknown_linux_gnu="$CROSS_TOOLCHAIN_PREFIX"ar \
    CC_riscv64gc_unknown_linux_gnu="$CROSS_TOOLCHAIN_PREFIX"gcc \
    CXX_riscv64gc_unknown_linux_gnu="$CROSS_TOOLCHAIN_PREFIX"g++ \
    CMAKE_TOOLCHAIN_FILE_riscv64gc_unknown_linux_gnu=/opt/toolchain.cmake \
    BINDGEN_EXTRA_CLANG_ARGS_riscv64gc_unknown_linux_gnu="--sysroot=$CROSS_SYSROOT" \
    RUST_TEST_THREADS=1 \
    PKG_CONFIG_ALLOW_CROSS_riscv64gc_unknown_linux_gnu=true \
    PKG_CONFIG_PATH="/usr/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/local/$CROSS_TOOLCHAIN/lib/pkgconfig/:/usr/lib/$CROSS_TOOLCHAIN/pkgconfig/" \
    CROSS_CMAKE_SYSTEM_NAME=Linux \
    CROSS_CMAKE_SYSTEM_PROCESSOR=riscv64gc \
    CROSS_CMAKE_CRT=gnu \
    CROSS_CMAKE_OBJECT_FLAGS="-ffunction-sections -fdata-sections -fPIC -march=rv64gc -mabi=lp64d -mcmodel=medany"

ENV CARGO_BUILD_TARGET=$RUST_TARGET \
    CARGO_TERM_COLOR=always

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
