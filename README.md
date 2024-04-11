# ink-cross-images

Cross compiling images for rust.

Images are updated weekly.

Built for x86_64 (amd64) and aarch64 (arm64) platforms.

## Pull

- From GitHub `docker pull ghcr.io/cargo-prebuilt/ink-cross:$DIST-$TARGET`
- From Quay `docker pull quay.io/cargo-prebuilt/ink-cross:$DIST-$TARGET`

## Using

Debug Build:

```shell
docker run --rm \
    --userns host --user $(id -u):$(id -g) \
    -v $HOME/.cargo/registry:/usr/local/cargo/registry \
    -v ./:/project \
    ghcr.io/cargo-prebuilt/ink-cross:stable-$TARGET
```

Release Build:

```shell
docker run --rm \
    --userns host --user $(id -u):$(id -g) \
    -v $HOME/.cargo/registry:/usr/local/cargo/registry \
    -v ./:/project \
    ghcr.io/cargo-prebuilt/ink-cross:stable-$TARGET \
    auditable build --verbose --release --locked
```

## Dists

There are 4 dists:
- Pinned: $VERSION-$TARGET (Only the latest rust version gets an updated image weekly)
- Stable: stable-$TARGET
- Beta: beta-$TARGET
- Nightly: nightly-$TARGET

## Targets

Only rust targets that have host tools can be built.

Info:
- experimental - Has not been extensively tested.
- bleeding - Has barely been tested.
- amd64 - Only available on amd64 platforms.
- nightly-only - Only builds and ships a nightly rust image.
  (Also is probably a [tier 3 rust target](https://doc.rust-lang.org/nightly/rustc/platform-support.html))

Targets:
- aarch64-unknown-freebsd (bleeding, nightly-only)
- aarch64-unknown-linux-gnu
- aarch64-unknown-linux-musl (experimental)
- armv7-unknown-linux-gnueabihf
- armv7-unknown-linux-musleabihf (experimental)
- powerpc64-unknown-linux-gnu (bleeding, amd64)
- powerpc64le-unknown-linux-gnu
- riscv64gc-unknown-linux-gnu
- s390x-unknown-linux-gnu
- x86_64-unknown-freebsd (experimental)
- x86_64-unknown-linux-gnu
- x86_64-unknown-linux-musl (experimental)
- x86_64-unknown-openbsd (bleeding, nightly-only)

## Differences between images

- GNU images use gcc.
  All other images use clang.
- GNU images are /usr/$CROSS_TOOLCHAIN/{include,lib}.
  All others are /usr/$CROSS_TOOLCHAIN/usr/{include,lib}.

## Acknowledgments

- [cross-rs](https://github.com/cross-rs/cross)
