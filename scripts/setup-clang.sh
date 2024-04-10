#!/bin/bash

set -euxo pipefail

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

# Get gcc toolchain
EXTRA=""
EXTRAPLUS=""
case "$CROSS_TOOLCHAIN" in
    *-musl*)
        EXTRA="--gcc-install-dir=$(realpath /usr/$CROSS_TOOLCHAIN/usr/lib/gcc/$CROSS_TOOLCHAIN/*/)"
        ;;
    *bsd*)
        EXTRAPLUS="-stdlib=libc++"
        ;;
esac

# Setup clang cross compile
mkdir -p "$CROSS_SYSROOT"/usr/bin

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"clang
echo "exec /usr/bin/clang-$LLVM_VERSION --target=$LLVM_TARGET --sysroot=$CROSS_SYSROOT $EXTRA \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"clang
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"clang

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"clang++
echo "exec /usr/bin/clang++-$LLVM_VERSION --target=$LLVM_TARGET --sysroot=$CROSS_SYSROOT $EXTRA $EXTRAPLUS \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"clang++
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"clang++

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ar
echo "exec /usr/bin/llvm-ar-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ar
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ar

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"as
echo "exec /usr/bin/llvm-as-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"as
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"as

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ld
echo "exec /usr/bin/lld-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ld
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ld

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"nm
echo "exec /usr/bin/llvm-nm-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"nm
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"nm

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"objcopy
echo "exec /usr/bin/llvm-objcopy-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"objcopy
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"objcopy

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"objdump
echo "exec /usr/bin/llvm-objdump-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"objdump
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"objdump

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ranlib
echo "exec /usr/bin/llvm-ranlib-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ranlib
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"ranlib

echo '#!/bin/sh' > "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"strip
echo "exec /usr/bin/llvm-strip-$LLVM_VERSION \"\$@\"" >> "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"strip
chmod +x "$CROSS_SYSROOT"/usr/bin/"$CROSS_TOOLCHAIN_PREFIX"strip

"$CROSS_TOOLCHAIN_PREFIX"clang --version
"$CROSS_TOOLCHAIN_PREFIX"clang++ --version
"$CROSS_TOOLCHAIN_PREFIX"ar --version
"$CROSS_TOOLCHAIN_PREFIX"ld --version || true
"$CROSS_TOOLCHAIN_PREFIX"nm --version
"$CROSS_TOOLCHAIN_PREFIX"objcopy --version
"$CROSS_TOOLCHAIN_PREFIX"objdump --version
"$CROSS_TOOLCHAIN_PREFIX"ranlib --version
"$CROSS_TOOLCHAIN_PREFIX"strip --version
