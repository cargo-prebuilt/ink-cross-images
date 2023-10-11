#!/bin/bash

set -euxo pipefail

mkdir -p /tmp/openssl
pushd /tmp/openssl

$EXT_CURL_CMD "https://www.openssl.org/source/$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz
tar -xzf openssl.tar.gz
rm -f openssl.tar.gz
cd "./$OPENSSL_VERSION"

AR="$CROSS_TOOLCHAIN_PREFIX"ar CC="$CROSS_TOOLCHAIN_PREFIX"gcc ./Configure $OPENSSL_COMBO \
    --libdir=lib --prefix="/usr/local/$CROSS_TOOLCHAIN" --openssldir="/usr/local/$CROSS_TOOLCHAIN/ssl" \
    no-dso no-shared no-ssl3 no-tests no-comp \
    no-legacy no-camellia no-idea no-seed

make "-j$(nproc)"
make "-j$(nproc)" install_sw
make "-j$(nproc)" install_ssldirs

popd
rm -rf /tmp/openssl
