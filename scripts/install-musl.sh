#!/bin/bash

set -euxo pipefail

mkdir -p /tmp/musl
pushd /tmp/musl

$EXT_CURL_CMD https://musl.libc.org/releases/musl-"$MUSL_VERSION".tar.gz -o musl.tar.gz
tar -xzvf musl.tar.gz
cd musl-"$MUSL_VERSION"

CROSS_COMPILE="$CROSS_TOOLCHAIN_PREFIX" CC="$CROSS_TOOLCHAIN_PREFIX"clang AR="$CROSS_TOOLCHAIN_PREFIX"ar \
    ./configure --prefix="$CROSS_SYSROOT" --disable-shared

make "-j$(nproc)"
make "-j$(nproc)" install

popd
rm -rf /tmp/musl
