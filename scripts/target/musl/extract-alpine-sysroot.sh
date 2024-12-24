#!/bin/bash

set -euxo pipefail

# Create sysroot
CHROOT=/opt/sysroot

mkdir -p $CHROOT/etc/apk/
cp /etc/apk/repositories $CHROOT/etc/apk/
cp /etc/resolv.conf $CHROOT/etc/

apk add -p "$CHROOT" --initdb -U --arch "$APK_ARCH" --allow-untrusted alpine-base

apk add -p "$CHROOT" gcc libstdc++-dev musl-dev linux-headers

# Extract
EXPORT=/opt/export

mkdir -p $EXPORT/lib/gcc/"$CROSS_TOOLCHAIN"

# Include
cp -r $CHROOT/usr/include $EXPORT

pushd $EXPORT/include/c++/*.*.*
mv ./*-alpine-linux-musl* "$CROSS_TOOLCHAIN"
popd

# Lib
rm -f $CHROOT/usr/lib/lib{crypto,ssl}.so*
cp $CHROOT/usr/lib/*.o $EXPORT/lib
cp $CHROOT/usr/lib/*.a $EXPORT/lib
cp $CHROOT/usr/lib/*.so* $EXPORT/lib

cp -r $CHROOT/usr/lib/gcc/*-alpine-linux-musl*/* $EXPORT/lib/gcc/"$CROSS_TOOLCHAIN"/

# Remove CHROOT
rm -rf $CHROOT
