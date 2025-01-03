#!/bin/bash

set -euxo pipefail

apt update

if [ -n "${GCC_PKGS+x}" ]; then
    apt install -y --no-install-recommends $GCC_PKGS
fi

rm -rf /var/lib/apt/lists/*
