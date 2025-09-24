#!/bin/bash

set -euxo pipefail

# Install LLVM repo
source /etc/os-release

$EXT_CURL_CMD https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc

echo 'Types: deb' > /etc/apt/sources.list.d/llvm.sources
echo '# https://apt.llvm.org/' >> /etc/apt/sources.list.d/llvm.sources
echo "URIs: http://apt.llvm.org/${VERSION_CODENAME}" >> /etc/apt/sources.list.d/llvm.sources
echo "Suites: llvm-toolchain-${VERSION_CODENAME}-${LLVM_VERSION}" >> /etc/apt/sources.list.d/llvm.sources
echo 'Components: main' >> /etc/apt/sources.list.d/llvm.sources
echo 'Signed-By: /etc/apt/trusted.gpg.d/apt.llvm.org.asc' >> /etc/apt/sources.list.d/llvm.sources
echo '' >> /etc/apt/sources.list.d/llvm.sources
