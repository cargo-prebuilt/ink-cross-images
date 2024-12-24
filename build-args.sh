#!/bin/bash

{
	echo "CMAKE_VERSION=3.31.2"
	#echo "OPENSSL_VERSION=openssl-3.4.0"
	echo "LLVM_VERSION=19"
	echo "MUSL_VERSION=1.2.5"
	echo "FREEBSD_MAJOR=13"
	echo "NETBSD_MAJOR=10"
	# Bypass openbsd cdn listing a release that is not out. (#36)
	echo "OPENBSD_MAJOR=7.6"
	# Dynamics
	echo "BUILD_DATE=$BUILD_DATE"
	echo "RUST_VERSION=$LATEST_RUST_VERSION"
	echo "OPENSSL_VERSION=$LATEST_OPENSSL_VERSION"
} >> "$GITHUB_ENV"
