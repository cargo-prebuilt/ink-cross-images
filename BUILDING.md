# Building

Ink Cross Images uses a justfile to build images using docker.
This allows easy building of the base images first, then the target image(s).

You need both just and docker installed.

- [Just](https://github.com/casey/just#installation)
- [Docker](https://www.docker.com/get-started/)

## Building default images

Images will be built under the ink:??? tag.

### Clang

Simply run `just target-clang $TARGET`.

### Gnu

Simply run `just target-gnu $TARGET`.

## Settings

### Platform

By default images are built for the `linux/arm64` platform, to build for another (or more) platform do

- `just --set platforms linux/$PLATFORM target-$GorC $TARGET`

or

- `just --set platforms linux/amd64,linux/arm64 target-$GorC $TARGET` (to build for both supported platforms)

### Rust Version

By default images are built with stable rust, to build for another version do

- `just --set rust_version nightly target-$GorC $TARGET`
