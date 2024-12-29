#!/bin/bash

set -euxo pipefail

# STEP = s0, s1, s2-clang, target
# IS_PULL_REQUEST = ${{ github.event_name == 'pull_request' }}
# RUST_VERSION
# TARGET

# Make sure all env vars are defined
[[ "${STEP}" == "" ]] && echo "Var STEP is not defined!" && exit 1
[[ "${IS_PULL_REQUEST}" == "" ]] && echo "Var IS_PULL_REQUEST is not defined!" && exit 1

### Do function that does #1
gen_tags() {
    local tagged="${1}"
    local tags=""

    if [[ "${IS_PULL_REQUEST}" == "false" ]]; then
        tags="ghcr.io/cargo-prebuilt/ink-cross:${tagged},quay.io/cargo-prebuilt/ink-cross:${tagged}"
    else
        tags="ghcr.io/cargo-prebuilt/ink-cross-dev:${tagged}"
    fi

    echo "${tags}"
}

case "$STEP" in
s0)
    echo "IMG_TAGS_PINNED=$(gen_tags "base-step0")" >> "$GITHUB_ENV"
    ;;
s1)
    [[ "${RUST_VERSION}" == "" ]] && echo "Var RUST_VERSION is not defined!" && exit 1
    {
        echo "IMG_TAGS_PINNED=$(gen_tags "base-step1-${RUST_VERSION}")"
        echo "IMG_TAGS_STABLE=$(gen_tags "base-step1-stable")"
        echo "IMG_TAGS_BETA=$(gen_tags "base-step1-beta")"
        echo "IMG_TAGS_NIGHTLY=$(gen_tags "base-step1-nightly")"
    } >> "$GITHUB_ENV"
    ;;
s2-clang)
    [[ "${RUST_VERSION}" == "" ]] && echo "Var RUST_VERSION is not defined!" && exit 1
    {
        echo "IMG_TAGS_PINNED=$(gen_tags "base-step2-clang-${RUST_VERSION}")"
        echo "IMG_TAGS_STABLE=$(gen_tags "base-step2-clang-stable")"
        echo "IMG_TAGS_BETA=$(gen_tags "base-step2-clang-beta")"
        echo "IMG_TAGS_NIGHTLY=$(gen_tags "base-step2-clang-nightly")"
    } >> "$GITHUB_ENV"
    ;;
target)
    [[ "${RUST_VERSION}" == "" ]] && echo "Var RUST_VERSION is not defined!" && exit 1
    [[ "${TARGET}" == "" ]] && echo "Var TARGET is not defined!" && exit 1
    {
        echo "IMG_TAGS_PINNED=$(gen_tags "${RUST_VERSION}-${TARGET}")"
        echo "IMG_TAGS_STABLE=$(gen_tags "stable-${TARGET}")"
        echo "IMG_TAGS_BETA=$(gen_tags "beta-${TARGET}")"
        echo "IMG_TAGS_NIGHTLY=$(gen_tags "nightly-${TARGET}")"
    } >> "$GITHUB_ENV"
    ;;
*)
    echo "STEP '$STEP' is not a defined step!"
    exit 1
    ;;
esac

if [[ "${IS_PULL_REQUEST}" == "false" ]]; then
    echo "IMG_REPO=ghcr.io/cargo-prebuilt/ink-cross" >> "$GITHUB_ENV"
else
    echo "IMG_REPO=ghcr.io/cargo-prebuilt/ink-cross-dev" >> "$GITHUB_ENV"
fi
