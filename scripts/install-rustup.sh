#!/bin/bash

set -euxo pipefail
mkdir -p /tmp/rustup
pushd /tmp/rustup

case "$TARGETARCH" in
amd64)
    export RUSTUP_ARCH="x86_64-unknown-linux-gnu"
    ;;
arm64)
    export RUSTUP_ARCH="aarch64-unknown-linux-gnu"
    ;;
*)
    echo "Unsupported Arch: $TARGETARCH" && exit 1
    ;;
esac

mkdir -p "target/$RUSTUP_ARCH/release"
$EXT_CURL_CMD "https://static.rust-lang.org/rustup/dist/$RUSTUP_ARCH/rustup-init" -o "target/$RUSTUP_ARCH/release/rustup-init"
$EXT_CURL_CMD "https://static.rust-lang.org/rustup/dist/$RUSTUP_ARCH/rustup-init.sha256" | sha256sum -c -
chmod +x "target/$RUSTUP_ARCH/release/rustup-init"
./"target/$RUSTUP_ARCH/release/rustup-init" -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host $RUSTUP_ARCH
chmod -R a+w $RUSTUP_HOME $CARGO_HOME

rustup component add --toolchain $RUST_VERSION clippy
rustup component add --toolchain $RUST_VERSION rustfmt

if [ "$RUST_VERSION" = "nightly" ]; then
    rustup toolchain install nightly --allow-downgrade -c rustfmt,clippy,miri
fi

popd
rm -rf /tmp/rustup
