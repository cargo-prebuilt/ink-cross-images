# ink-cross-images

Cross compiling images for rust.

Images are updated weekly.

Built for x86_64 (amd64) and aarch64 (arm64) platforms.

## Pull

- From GitHub `docker pull ghcr.io/cargo-prebuilt/ink-cross:$DIST-$TARGET`
- From Quay `docker pull quay.io/cargo-prebuilt/ink-cross:$DIST-$TARGET`

## Dists

There are 4 dists:
- Pinned: $VERSION-$TARGET (Only the latest rust version gets an updated image weekly)
- Stable: stable-$TARGET
- Beta: beta-$TARGET
- Nightly: nightly-$TARGET

## Targets

- aarch64-unknown-linux-gnu
- aarch64-unknown-linux-musl
- armv7-unknown-linux-gnueabihf
- armv7-unknown-linux-musleabihf
- powerpc64le-unknown-linux-gnu
- riscv64gc-unknown-linux-gnu
- s390x-unknown-linux-gnu
- x86_64-unknown-linux-gnu
- x86_64-unknown-linux-musl

## Differences between images

- Gnu images use gcc
- Musl images use clang
