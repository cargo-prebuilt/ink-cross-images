#!/bin/bash

set -euxo pipefail

apt update
apt upgrade -y --no-install-recommends
apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    lsb-release \
    pkg-config \
    bison \
    flex \
    texinfo \
    autoconf \
    automake \
    make \
    libtool \
    libtool-bin \
    git \
    perl \
    xz-utils \
    meson \
    ninja-build

if [ ! -z "${GCC_PKGS+x}" ]; then
    apt install -y --no-install-recommends $GCC_PKGS
fi

rm -rf /var/lib/apt/lists/*
