# ink-cross-images

Cross compiling images for rust.

Images are updated weekly.

Built for x86_64 (amd64) and aarch64 (arm64) platforms.

## Pull

- From GitHub `docker pull ghcr.io/cargo-prebuilt/ink-cross:$DIST-$TARGET`
- From Quay `docker pull quay.io/cargo-prebuilt/ink-cross:$DIST-$TARGET`

### Dev Images

> [!WARNING]
> Dev images are only hosted on GitHub and are built in pull requests.
> They are not rebuilt weekly and are not meant for general use.

`docker pull ghcr.io/cargo-prebuilt/ink-cross-dev:$DIST-$TARGET`

## Using

Debug Build:

```shell
docker run --rm \
    --userns host --user "$(id -u):$(id -g)" \
    -v "$HOME/.cargo/registry:/usr/local/cargo/registry" \
    -v ./:/project \
    ghcr.io/cargo-prebuilt/ink-cross:stable-$TARGET
```

Release Build:

```shell
docker run --rm \
    --userns host --user "$(id -u):$(id -g)" \
    -v "$HOME/.cargo/registry:/usr/local/cargo/registry" \
    -v ./:/project \
    ghcr.io/cargo-prebuilt/ink-cross:stable-$TARGET \
    auditable build --verbose --release --locked
```

*`--userns host --user "$(id -u):$(id -g)"` may or may not be needed.*

## Dists

There are 4 dists:
- Pinned: $VERSION-$TARGET

  *(ENTRYPOINT runs `cargo +$VERSION $@`)*

  (Only the latest rust version gets an updated image weekly)

- Stable: stable-$TARGET

  *(ENTRYPOINT runs `cargo +stable $@`)*

- Beta: beta-$TARGET

  *(ENTRYPOINT runs `cargo +beta $@`)*

- Nightly: nightly-$TARGET

  *(ENTRYPOINT runs `cargo +nightly $@`)*

## Targets

Only rust targets that have host tools can be built.

Info:
- experimental - Has not been extensively tested.
- bleeding - Has barely been tested.
- amd64 - Only available on amd64 platforms.
- nightly-only - Only builds and ships a nightly rust image.
  (Also is probably a [tier 3 rust target](https://doc.rust-lang.org/nightly/rustc/platform-support.html))

### Clang Targets

Use Clang as their cross compiler and linker.
Libs are under `/usr/$CROSS_TOOLCHAIN/usr/{include,lib}`.

- aarch64-unknown-freebsd (bleeding, nightly-only)
- aarch64-unknown-linux-musl
- armv7-unknown-linux-musleabihf
- x86_64-unknown-freebsd
- x86_64-unknown-linux-musl
- x86_64-unknown-netbsd
- x86_64-unknown-openbsd (bleeding, nightly-only)

### GNU Targets

Use GCC as their cross compiler and linker.
Libs are under `/usr/$CROSS_TOOLCHAIN/{include,lib}`.

- aarch64-unknown-linux-gnu
- armv7-unknown-linux-gnueabihf
- powerpc64-unknown-linux-gnu (bleeding, amd64)
- powerpc64le-unknown-linux-gnu
- riscv64gc-unknown-linux-gnu
- s390x-unknown-linux-gnu
- sparc64-unknown-linux-gnu (bleeding, amd64)
- x86_64-unknown-linux-gnu

### All Targets

- aarch64-unknown-freebsd (bleeding, nightly-only)
- aarch64-unknown-linux-gnu
- aarch64-unknown-linux-musl
- armv7-unknown-linux-gnueabihf
- armv7-unknown-linux-musleabihf
- powerpc64-unknown-linux-gnu (bleeding, amd64)
- powerpc64le-unknown-linux-gnu
- riscv64gc-unknown-linux-gnu
- s390x-unknown-linux-gnu
- sparc64-unknown-linux-gnu (bleeding, amd64)
- x86_64-unknown-freebsd
- x86_64-unknown-linux-gnu
- x86_64-unknown-linux-musl
- x86_64-unknown-netbsd
- x86_64-unknown-openbsd (bleeding, nightly-only)

## Auditing

All scripts + the dockerfile are included under `/ink` directory in the image.

## Acknowledgments

- Uses some scripts from [cross-rs](https://github.com/cross-rs/cross)
