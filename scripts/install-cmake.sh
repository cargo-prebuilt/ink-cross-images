#!/bin/bash

set -euxo pipefail

mkdir -p /tmp/cmake
pushd /tmp/cmake

case "$TARGETARCH" in
amd64)
    export CMAKE_ARCH="x86_64"
    ;;
arm64)
    export CMAKE_ARCH="aarch64"
    ;;
*)
    echo "Unsupported Arch: $TARGETARCH" && exit 1
    ;;
esac
$EXT_CURL_CMD "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-$CMAKE_ARCH.sh" -O
$EXT_CURL_CMD "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-SHA-256.txt" | sha256sum -c --ignore-missing -
sh "cmake-$CMAKE_VERSION-linux-$CMAKE_ARCH.sh" --skip-license --prefix=/usr/local

popd
rm -rf /tmp/cmake
