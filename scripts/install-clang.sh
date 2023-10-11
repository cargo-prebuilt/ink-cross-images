#!/bin/bash

# Install clang
apt update
apt install -y wget software-properties-common gnupg

mkdir -p /tmp/llvm
pushd /tmp/llvm

$EXT_CURL_CMD https://apt.llvm.org/llvm.sh -o llvm.sh
chmod +x llvm.sh
./llvm.sh "$LLVM_VERSION"

# Needed because running it the first time fails to find packages.
set -euxo pipefail # Since the first time will always fail.
./llvm.sh "$LLVM_VERSION"

popd
rm -rf /tmp/llvm

apt purge -y wget software-properties-common gnupg
apt autoremove -y
rm -rf /var/lib/apt/lists/*

clang-"$LLVM_VERSION" --version

# Set clang alts
update-alternatives --install /usr/bin/clang clang /usr/bin/clang-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/cc cc /usr/bin/clang-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-"$LLVM_VERSION" 100

update-alternatives --install /usr/bin/lld lld /usr/bin/lld-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/ld ld /usr/bin/lld-"$LLVM_VERSION" 100

update-alternatives --install /usr/bin/ar ar /usr/bin/llvm-ar-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/as as /usr/bin/llvm-as-"$LLVM_VERSION" 100

update-alternatives --install /usr/bin/nm nm /usr/bin/llvm-nm-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/objcopy objcopy /usr/bin/llvm-objcopy-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/objdump objdump /usr/bin/llvm-objdump-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/ranlib ranlib /usr/bin/llvm-ranlib-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/strip strip /usr/bin/llvm-strip-"$LLVM_VERSION" 100
update-alternatives --install /usr/bin/strings strings /usr/bin/llvm-strings-"$LLVM_VERSION" 100

# Setup clang cross compile
mkdir -p "$CROSS_SYSROOT"/bin

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"clang
echo "exec /usr/bin/clang-$LLVM_VERSION --target=$LLVM_TARGET --sysroot=$CROSS_SYSROOT \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"clang
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"clang

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"clang++
echo "exec /usr/bin/clang++-$LLVM_VERSION --target=$LLVM_TARGET --sysroot=$CROSS_SYSROOT -stdlib=libc++ \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"clang++
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"clang++

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ar
echo "exec /usr/bin/llvm-ar-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ar
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ar

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"as
echo "exec /usr/bin/llvm-as-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"as
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"as

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ld
echo "exec /usr/bin/lld-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ld
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ld

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"nm
echo "exec /usr/bin/llvm-nm-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"nm
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"nm

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"objcopy
echo "exec /usr/bin/llvm-objcopy-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"objcopy
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"objcopy

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"objdump
echo "exec /usr/bin/llvm-objdump-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"objdump
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"objdump

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ranlib
echo "exec /usr/bin/llvm-ranlib-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ranlib
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"ranlib

echo '#!/bin/sh' >"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"strip
echo "exec /usr/bin/llvm-strip-$LLVM_VERSION \"\$@\"" >>"$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"strip
chmod +x "$CROSS_SYSROOT"/bin/"$CROSS_TOOLCHAIN_PREFIX"strip

"$CROSS_TOOLCHAIN_PREFIX"clang --version
"$CROSS_TOOLCHAIN_PREFIX"clang++ --version
"$CROSS_TOOLCHAIN_PREFIX"ar --version
"$CROSS_TOOLCHAIN_PREFIX"ld --version || true
"$CROSS_TOOLCHAIN_PREFIX"nm --version
"$CROSS_TOOLCHAIN_PREFIX"objcopy --version
"$CROSS_TOOLCHAIN_PREFIX"objdump --version
"$CROSS_TOOLCHAIN_PREFIX"ranlib --version
"$CROSS_TOOLCHAIN_PREFIX"strip --version
