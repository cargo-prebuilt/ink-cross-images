#!/bin/bash

set -euxo pipefail

apt update
apt upgrade -y --no-install-recommends
apt install -y --no-install-recommends \
    autoconf \
    automake \
    bison \
    ca-certificates \
    curl \
    flex \
    git \
    libtool \
    libtool-bin \
    lsb-release \
    make \
    meson \
    nano \
    ninja-build \
    perl \
    pkg-config \
    texinfo \
    xz-utils

apt autoremove -y
rm -rf /var/lib/apt/lists/*
