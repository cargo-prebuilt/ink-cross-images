#!/bin/bash

set -euxo pipefail

# Install clang
apt update

apt update
apt install -y --no-install-recommends "clang-$LLVM_VERSION" "libclang-$LLVM_VERSION-dev" "lld-$LLVM_VERSION" "llvm-$LLVM_VERSION"

apt autoremove -y
rm -rf /var/lib/apt/lists/*

clang-"$LLVM_VERSION" --version
