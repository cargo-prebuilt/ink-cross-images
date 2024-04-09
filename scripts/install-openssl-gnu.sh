#!/bin/bash

set -euxo pipefail

mkdir -p /tmp/openssl
pushd /tmp/openssl

git clone --depth=1 -b "$OPENSSL_VERSION" https://github.com/openssl/openssl.git openssl
cd ./openssl

AR="$CROSS_TOOLCHAIN_PREFIX"ar CC="$CROSS_TOOLCHAIN_PREFIX"gcc ./Configure $OPENSSL_COMBO \
    --libdir=lib --prefix="$CROSS_SYSROOT" --openssldir="/usr/local/$CROSS_TOOLCHAIN/ssl" \
    no-dso no-shared no-ssl3 no-tests no-comp \
    no-legacy no-camellia no-idea no-seed

make "-j$(nproc)"
make "-j$(nproc)" install_sw
make "-j$(nproc)" install_ssldirs

popd
rm -rf /tmp/openssl
