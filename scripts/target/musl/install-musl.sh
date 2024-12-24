#!/bin/bash

set -euxo pipefail

mkdir -p /tmp/musl
pushd /tmp/musl

git clone --depth=1 -b v"$MUSL_VERSION" https://git.musl-libc.org/git/musl musl
cd ./musl

CROSS_COMPILE="$CROSS_TOOLCHAIN_PREFIX" CC="$CROSS_TOOLCHAIN_PREFIX"clang AR="$CROSS_TOOLCHAIN_PREFIX"ar \
    ./configure --prefix="$CROSS_SYSROOT"/usr --disable-shared --enable-optimize=*

make "-j$(nproc)"
make "-j$(nproc)" install

popd
rm -rf /tmp/musl
