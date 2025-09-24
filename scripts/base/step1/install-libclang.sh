#!/bin/bash

set -euxo pipefail

# Install libclang
apt update
apt install -y --no-install-recommends "libclang-$LLVM_VERSION-dev"

apt autoremove -y
rm -rf /var/lib/apt/lists/*
