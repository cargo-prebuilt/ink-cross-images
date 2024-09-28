#!/bin/bash

set -euxo pipefail

### https://github.com/cross-rs/cross/blob/main/docker/freebsd.sh
max_openbsd() {
    local best="$OPENBSD_MAJOR.0"
    local minor=0
    local version=
    local release_major=
    local release_minor=
    for release in "${@}"; do
        version=$(echo "${release}" | cut -d '-' -f 1)
        release_major=$(echo "${version}"| cut -d '.' -f 1)
        release_minor=$(echo "${version}"| cut -d '.' -f 2)
        if [ "${release_major}" == "${OPENBSD_MAJOR}" ] && [ "${release_minor}" -gt "${minor}" ]; then
            best="${release}"
            minor="${release_minor}"
        fi
    done
    if [[ -z "$best" ]]; then
        echo -e "\e[31merror:\e[0m could not find best release for OpenBSD ${OPENBSD_MAJOR}." 1>&2
        exit 1
    fi
    echo "${best}"
}

latest_openbsd() {
    local mirror="${1}"
    local response=
    local line=
    local lines=
    local releases=
    local max_release=

    response=$(curl --retry 3 -sSfL "${mirror}/" | grep \>${OPENBSD_MAJOR}\.)
    if [[ ! -n "${response}" ]]; then
        echo -e "\e[31merror:\e[0m could not find a candidate release for OpenBSD ${OPENBSD_MAJOR}." 1>&2
        exit 1
    fi
    readarray -t lines <<< "${response}"

    # shellcheck disable=SC2016
    local regex='/<a.*?>\s*(\d+\.\d+)\s*\/?\s*<\/a>/; print $1'
    # not all lines will match: some return `*-RELEASE/` as a line
    if [[ "${response}" == *"<a"* ]]; then
        # have HTML output, need to extract it via a regex
        releases=()
        for line in "${lines[@]}"; do
            if [[ "${line}" == *"<a"* ]]; then
                # because of the pattern we're extracting, this can't split
                # shellcheck disable=SC2207
                releases+=($(echo "${line}" | perl -nle "${regex}"))
            fi
        done
    else
        releases=("${lines[@]}")
    fi

    max_release=$(max_openbsd "${releases[@]}")
    echo "${max_release}"
}
###

mkdir -p /tmp/openbsd
pushd /tmp/openbsd

# Bypass openbsd cdn listing a release that is not out. (#36)
OPENBSD_VERSION="$OPENBSD_MAJOR"

#OPENBSD_VERSION="$(latest_openbsd 'https://cdn.openbsd.org/pub/OpenBSD')"
OPENBSD_URL="https://cdn.openbsd.org/pub/OpenBSD/$OPENBSD_VERSION/$OPENBSD_ARCH/"

$EXT_CURL_CMD "$OPENBSD_URL"base"${OPENBSD_VERSION//.}".tgz -o base.tgz
mkdir -p ./openbsd
tar -xzf base.tgz -C ./openbsd

mkdir -p "$CROSS_SYSROOT"/usr
mkdir -p "$CROSS_SYSROOT"/usr/include
mkdir -p "$CROSS_SYSROOT"/usr/lib

rm -rf ./openbsd/usr/lib/locate
rm -rf ./openbsd/usr/lib/pkgconfig
rm -f ./openbsd/usr/lib/libLLVM* # LLVM is really heavy and we probably do not need it?
cp -r ./openbsd/usr/lib "$CROSS_SYSROOT"/usr

rm -rf ./openbsd
$EXT_CURL_CMD "$OPENBSD_URL"comp"${OPENBSD_VERSION//.}".tgz -o comp.tgz
mkdir -p ./openbsd
tar -xzvf comp.tgz -C ./openbsd

rm -rf ./openbsd/usr/include/llvm # LLVM is really heavy and we probably do not need it?
cp -r ./openbsd/usr/include "$CROSS_SYSROOT"/usr

rm -rf ./openbsd/usr/lib/clang
rm -rf ./openbsd/usr/lib/debug
rm -f ./openbsd/usr/lib/lib{crypto,ssl,tls}{,_p}.a
cp ./openbsd/usr/lib/*.a "$CROSS_SYSROOT"/usr/lib

popd
rm -rf /tmp/openbsd
