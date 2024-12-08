#!/bin/bash

echo "CMAKE_VERSION=3.31.2" >> $GITHUB_ENV
echo "OPENSSL_VERSION=openssl-3.4.0" >> $GITHUB_ENV
echo "LLVM_VERSION=19" >> $GITHUB_ENV
echo "MUSL_VERSION=1.2.5" >> $GITHUB_ENV
echo "FREEBSD_MAJOR=13" >> $GITHUB_ENV
echo "NETBSD_MAJOR=10" >> $GITHUB_ENV
# Bypass openbsd cdn listing a release that is not out. (#36)
echo "OPENBSD_MAJOR=7.6" >> $GITHUB_ENV
