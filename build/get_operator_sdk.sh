#!/bin/bash

set -x

REL=$(dirname "$0")
ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
OS=$(uname | awk '{print tolower($0)}')
VERSION="${1:-v1.5.0}"
OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/${VERSION}

OPERATOR_SDK_SHA256="${2:-04bb2ea8ed6e1b790c6285c0a3a6f0f49cddacbbedf05a9bf5d181370048af3e}"

if [[ ! -f ${REL}/working/operator-sdk-${VERSION} ]]; then
	mkdir ${REL}/working
	if [[ "${VERSION}" =~ "v0" ]]; then
		# naming scheme for v0.x is operator-sdk-$VERSION-$ARCH-$OS e.g. operator-sdk-v0.19.4-x86_64-linux-gnu
		curl -L ${OPERATOR_SDK_DL_URL}/operator-sdk-${VERSION}-x86_64-linux-gnu -o ${REL}/working/operator-sdk-${VERSION}
    else
		# naming scheme for v1.x is operator-sdk_$OS-$ARCH e.g. operator-sdk_linux_amd64
		curl -L ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH} -o ${REL}/working/operator-sdk-${VERSION}
	fi
	echo "${OPERATOR_SDK_SHA256}  ${REL}/working/operator-sdk-${VERSION}" | sha256sum -c - || { rm -f ${REL}/working/operator-sdk-${VERSION}; exit 1; }
	chmod +x ${REL}/working/operator-sdk-${VERSION}
	rm -f ${REL}/working/operator-sdk
fi

set +x