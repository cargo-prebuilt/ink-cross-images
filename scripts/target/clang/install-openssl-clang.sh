#!/bin/bash

set -euxo pipefail

pushd "/tmp/${RUST_TARGET}/${TARGETARCH}/openssl"

# Cache String
CACHE_STR="/tmp/${RUST_TARGET}/${TARGETARCH}/openssl/OPENSSL.CACHETAG
SCRIPT_TYPE=clang
OPENSSL_VERSION=${OPENSSL_VERSION}
CACHE_BUST=${CACHE_BUST}
AR=${CROSS_TOOLCHAIN_PREFIX}ar
CC=${CROSS_TOOLCHAIN_PREFIX}clang
OPENSSL_COMBO=${OPENSSL_COMBO}
CROSS_SYSROOT=${CROSS_SYSROOT}
CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}"

if [ ! -e OPENSSL.CACHETAG ] || [[ $(< OPENSSL.CACHETAG) != "${CACHE_STR}" ]]; then
    rm -rf ./*

    git clone --depth=1 -b "${OPENSSL_VERSION}" https://github.com/openssl/openssl.git openssl
    pushd ./openssl

    AR="$CROSS_TOOLCHAIN_PREFIX"ar CC="$CROSS_TOOLCHAIN_PREFIX"clang ./Configure "$OPENSSL_COMBO" \
        --libdir=lib --prefix="$CROSS_SYSROOT"/usr --openssldir="/usr/local/$CROSS_TOOLCHAIN/ssl" \
        no-dso no-shared no-ssl3 no-tests no-comp \
        no-legacy no-camellia no-idea no-seed

    make "-j$(nproc)"

    popd
    echo "${CACHE_STR}" > "OPENSSL.CACHETAG"
fi

pushd ./openssl

make "-j$(nproc)" install_sw
make "-j$(nproc)" install_ssldirs

popd
popd
