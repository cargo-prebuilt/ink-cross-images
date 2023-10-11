#!/bin/bash

set -euxo pipefail

apt update
apt upgrade -y --no-install-recommends
apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    lsb-release \
    pkg-config \
    autoconf \
    automake \
    make \
    libtool \
    git \
    perl \
    xz-utils

if [ ! -z "$GCC_PKGS" ]; then
    apt install -y --no-install-recommends $GCC_PKGS
fi

rm -rf /var/lib/apt/lists/*
