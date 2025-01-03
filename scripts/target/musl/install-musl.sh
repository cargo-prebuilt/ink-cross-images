#!/bin/bash

set -euxo pipefail

pushd "/tmp/${RUST_TARGET}/${TARGETARCH}/musl"

# Cache String
CACHE_STR="/tmp/${RUST_TARGET}/${TARGETARCH}/musl/MUSL.CACHETAG
MUSL_VERSION=${MUSL_VERSION}
CACHE_BUST=${CACHE_BUST}
CROSS_COMPILE=${CROSS_TOOLCHAIN_PREFIX}
AR=${CROSS_TOOLCHAIN_PREFIX}ar
CC=${CROSS_TOOLCHAIN_PREFIX}clang
CROSS_SYSROOT=${CROSS_SYSROOT}
CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}"

if [ ! -e MUSL.CACHETAG ] || [[ $(< MUSL.CACHETAG) != "${CACHE_STR}" ]]; then
    rm -rf ./*

    git clone --depth=1 -b v"${MUSL_VERSION}" https://git.musl-libc.org/git/musl musl
    pushd ./musl

    CROSS_COMPILE="$CROSS_TOOLCHAIN_PREFIX" CC="$CROSS_TOOLCHAIN_PREFIX"clang AR="$CROSS_TOOLCHAIN_PREFIX"ar \
        ./configure --prefix="$CROSS_SYSROOT"/usr --disable-shared --enable-optimize=*

    make "-j$(nproc)"

    popd
    echo "${CACHE_STR}" > "MUSL.CACHETAG"
fi

pushd ./musl

make "-j$(nproc)" install

popd
popd
