#!/bin/bash

set -euxo pipefail

# Install clang
apt update
apt install -y software-properties-common gnupg

source /etc/os-release

$EXT_CURL_CMD https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc

# Why is this needed...
add-apt-repository -y "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-$LLVM_VERSION main"
add-apt-repository -y "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-$LLVM_VERSION main"

apt update
apt install -y "clang-$LLVM_VERSION" "lld-$LLVM_VERSION" "llvm-$LLVM_VERSION"

apt purge -y software-properties-common gnupg
apt autoremove -y
rm -rf /var/lib/apt/lists/*

clang-"$LLVM_VERSION" --version
