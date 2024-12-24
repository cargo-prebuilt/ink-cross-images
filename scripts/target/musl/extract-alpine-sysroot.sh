#!/bin/bash

set -euxo pipefail

pushd "/opt/${CROSS_TOOLCHAIN}/extract"

CHROOT="/opt/${CROSS_TOOLCHAIN}/extract/sysroot"
EXPORT="/opt/${CROSS_TOOLCHAIN}/extract/export"

# Cache String
CACHE_STR="/opt/${CROSS_TOOLCHAIN}/extract/ALPINE.CACHETAG
ALPINE_VERSION=${ALPINE_VERSION}
CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
APK_ARCH=${APK_ARCH}
CACHE_BUST=${CACHE_BUST}
CHROOT=${CHROOT}
EXPORT=${EXPORT}"

if [ ! -e ALPINE.CACHETAG ] || [[ $(< ALPINE.CACHETAG) != "${CACHE_STR}" ]]; then
    rm -rf ./*

    # Create sysroot
    mkdir -p "$CHROOT/etc/apk/"
    cp /etc/apk/repositories "$CHROOT/etc/apk/"
    cp /etc/resolv.conf "$CHROOT/etc/"

    apk add -p "$CHROOT" --initdb -U --arch "$APK_ARCH" --allow-untrusted alpine-base

    apk add -p "$CHROOT" gcc libstdc++-dev musl-dev linux-headers

    # Extract
    mkdir -p "$EXPORT/lib/gcc/$CROSS_TOOLCHAIN"

    # Include
    cp -r "$CHROOT/usr/include" "$EXPORT"

    pushd "$EXPORT"/include/c++/*.*.*
    mv ./*-alpine-linux-musl* "$CROSS_TOOLCHAIN"
    popd

    # Lib
    rm -f "$CHROOT"/usr/lib/lib{crypto,ssl}.so*
    cp "$CHROOT"/usr/lib/*.o "$EXPORT/lib"
    cp "$CHROOT"/usr/lib/*.a "$EXPORT/lib"
    cp "$CHROOT"/usr/lib/*.so* "$EXPORT/lib"

    cp -r "$CHROOT"/usr/lib/gcc/*-alpine-linux-musl*/* "$EXPORT/lib/gcc/$CROSS_TOOLCHAIN/"

    # Remove CHROOT
    rm -rf "$CHROOT"

    echo "${CACHE_STR}" > "ALPINE.CACHETAG"
fi

mkdir -p /opt/export
cp -r "$EXPORT"/* "/opt/export/"

popd
