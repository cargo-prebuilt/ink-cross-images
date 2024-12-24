#!/bin/bash

set -euxo pipefail

### https://github.com/cross-rs/cross/blob/main/docker/freebsd.sh
max_netbsd() {
    local best="$NETBSD_MAJOR.0"
    local minor=0
    local version=
    local release_major=
    local release_minor=
    for release in "${@}"; do
        version=$(echo "${release}" | cut -d '-' -f 1)
        release_major=$(echo "${version}"| cut -d '.' -f 1)
        release_minor=$(echo "${version}"| cut -d '.' -f 2)
        if [ "${release_major}" == "${NETBSD_MAJOR}" ] && [ "${release_minor}" -gt "${minor}" ]; then
            best="${release}"
            minor="${release_minor}"
        fi
    done
    if [[ -z "$best" ]]; then
        echo -e "\e[31merror:\e[0m could not find best release for NetBSD ${NETBSD_MAJOR}." 1>&2
        exit 1
    fi
    echo "${best}"
}

latest_netbsd() {
    local mirror="${1}"
    local response=
    local line=
    local lines=
    local releases=
    local max_release=

    response=$(curl --retry 3 -sSfL "${mirror}/" | grep NetBSD)
    if [[ "${response}" != *NetBSD* ]]; then
        echo -e "\e[31merror:\e[0m could not find a candidate release for NetBSD ${NETBSD_MAJOR}." 1>&2
        exit 1
    fi
    readarray -t lines <<< "${response}"

    # shellcheck disable=SC2016
    local regex='/<a.*?>\s*(NetBSD-\d+\.\d+)\s*\/?\s*<\/a>/; print $1'
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

    max_release=$(max_netbsd "${releases[@]}")
    echo "${max_release//NetBSD-/}"
}
###

pushd "/tmp/${RUST_TARGET}/${TARGETARCH}/netbsd"

NETBSD_VERSION="$(latest_netbsd 'https://ftp.netbsd.org/pub/NetBSD')"
NETBSD_URL="https://ftp.netbsd.org/pub/NetBSD/NetBSD-$NETBSD_VERSION/$NETBSD_ARCH/binary/sets/"

# Cache String
CACHE_STR="/tmp/${RUST_TARGET}/${TARGETARCH}/netbsd/NETBSD.CACHETAG
NETBSD_VERSION=${NETBSD_VERSION}
NETBSD_URL=${NETBSD_URL}
CACHE_BUST=${CACHE_BUST}
EXT_CURL_CMD=${EXT_CURL_CMD}
CROSS_SYSROOT=${CROSS_SYSROOT}"

if [ ! -e NETBSD.CACHETAG ] || [[ $(< NETBSD.CACHETAG) != "${CACHE_STR}" ]]; then
    rm -rf ./*

    $EXT_CURL_CMD "$NETBSD_URL"base.tar.xz -o base.tar.xz
    mkdir -p ./netbsd
    tar -xJf base.tar.xz -C ./netbsd

    $EXT_CURL_CMD "$NETBSD_URL"comp.tar.xz -o comp.tar.xz
    tar -xJf comp.tar.xz -C ./netbsd

    echo "${CACHE_STR}" > "NETBSD.CACHETAG"
fi

mkdir -p "$CROSS_SYSROOT"/usr
mkdir -p "$CROSS_SYSROOT"/usr/include
mkdir -p "$CROSS_SYSROOT"/usr/lib

cp -r ./netbsd/usr/include "$CROSS_SYSROOT"/usr
cp -r ./netbsd/lib/* "$CROSS_SYSROOT"/usr/lib

cp ./netbsd/usr/lib/libc.so* "$CROSS_SYSROOT"/usr/lib
cp ./netbsd/usr/lib/libc{,_p}.a "$CROSS_SYSROOT"/usr/lib

cp ./netbsd/usr/lib/libs*c++.{so,a}* "$CROSS_SYSROOT"/usr/lib
cp ./netbsd/usr/lib/libstdc++_p.a "$CROSS_SYSROOT"/usr/lib

cp ./netbsd/usr/lib/lib{m,util,pthread,execinfo}.so* "$CROSS_SYSROOT"/usr/lib
cp ./netbsd/usr/lib/lib{m,util,pthread,execinfo}{,_p}.a "$CROSS_SYSROOT"/usr/lib

cp ./netbsd/usr/lib/libgcc*.{so,a}* "$CROSS_SYSROOT"/usr/lib
cp ./netbsd/usr/lib/librt*.{so,a}* "$CROSS_SYSROOT"/usr/lib
cp ./netbsd/usr/lib/*crt*.o "$CROSS_SYSROOT"/usr/lib
cp ./netbsd/usr/lib/libkvm.{so,a}* "$CROSS_SYSROOT"/usr/lib

popd
