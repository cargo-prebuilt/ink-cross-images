#!/bin/bash

set -euxo pipefail

### https://github.com/cross-rs/cross/blob/main/docker/freebsd.sh
max_freebsd() {
    local best="$FREEBSD_MAJOR.0"
    local minor=0
    local version=
    local release_major=
    local release_minor=
    for release in "${@}"; do
        version=$(echo "${release}" | cut -d '-' -f 1)
        release_major=$(echo "${version}"| cut -d '.' -f 1)
        release_minor=$(echo "${version}"| cut -d '.' -f 2)
        if [ "${release_major}" == "${FREEBSD_MAJOR}" ] && [ "${release_minor}" -gt "${minor}" ]; then
            best="${release}"
            minor="${release_minor}"
        fi
    done
    if [[ -z "$best" ]]; then
        echo -e "\e[31merror:\e[0m could not find best release for FreeBSD ${FREEBSD_MAJOR}." 1>&2
        exit 1
    fi
    echo "${best}"
}

latest_freebsd() {
    local mirror="${1}"
    local response=
    local line=
    local lines=
    local releases=
    local max_release=

    response=$(curl --retry 3 -sSfL "${mirror}/${FREEBSD_ARCH}/" | grep RELEASE)
    if [[ "${response}" != *RELEASE* ]]; then
        echo -e "\e[31merror:\e[0m could not find a candidate release for FreeBSD ${FREEBSD_MAJOR}." 1>&2
        exit 1
    fi
    readarray -t lines <<< "${response}"

    # shellcheck disable=SC2016
    local regex='/<a.*?>\s*(\d+\.\d+-RELEASE)\s*\/?\s*<\/a>/; print $1'
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

    max_release=$(max_freebsd "${releases[@]}")
    echo "${max_release//-RELEASE/}"
}
###

mkdir -p /tmp/freebsd
pushd /tmp/freebsd

FREEBSD_VERSION="$(latest_freebsd 'https://download.freebsd.org/ftp/releases')"
FREEBSD_URL="https://download.freebsd.org/ftp/releases/$FREEBSD_ARCH/$FREEBSD_VERSION-RELEASE/"

$EXT_CURL_CMD "$FREEBSD_URL"base.txz -o base.txz
mkdir -p ./freebsd
tar -xJvf base.txz -C ./freebsd

mkdir -p "$CROSS_SYSROOT"/usr
mkdir -p "$CROSS_SYSROOT"/usr/include
mkdir -p "$CROSS_SYSROOT"/usr/lib

# https://github.com/cross-rs/cross/blob/main/docker/freebsd.sh
cp -r ./freebsd/usr/include "$CROSS_SYSROOT"/usr
cp -r ./freebsd/lib/* "$CROSS_SYSROOT"/usr/lib

cp ./freebsd/usr/lib/libc++.so.1 "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/libc++.a "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/libcxxrt.a "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/{libcompiler_rt,libgcc}.a "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/lib{c,util,m,ssp_nonshared,memstat}.a "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/lib{rt,execinfo,procstat}.so.1 "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/libmemstat.so.3 "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/*crt*.o "$CROSS_SYSROOT"/usr/lib
cp ./freebsd/usr/lib/libkvm.a "$CROSS_SYSROOT"/usr/lib

#rm -f ./freebsd/usr/lib/*_p.*
#cp ./freebsd/usr/lib/*.a "$CROSS_SYSROOT"/usr/lib
#cp ./freebsd/usr/lib/*.so.* "$CROSS_SYSROOT"/usr/lib
#cp ./freebsd/usr/lib/*crt*.o "$CROSS_SYSROOT"/usr/lib

echo "GROUP ( /usr/lib/libc++.so.1 /usr/lib/libcxxrt.so )" > "$CROSS_SYSROOT"/usr/lib/libc++.so

for lib in "$CROSS_SYSROOT"/usr/lib/*.so.*; do
    LINK="$(basename "$lib")"
    LINK="${LINK%.*}"
    [ ! -f "$CROSS_SYSROOT"/usr/lib/"$LINK" ] && echo "Made $LINK link" && ln -s "$lib" "$CROSS_SYSROOT"/usr/lib/"$LINK"
done

ln -sf "$CROSS_SYSROOT"/usr/lib/libthr.so.3 "$CROSS_SYSROOT"/usr/lib/libpthread.so

popd
rm -rf /tmp/freebsd
