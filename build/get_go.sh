#!/bin/bash

REL=$(dirname "$0")
ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
OS=$(uname | awk '{print tolower($0)}')
VERSION="${1:-1.16}"
ARCHIVE_NAME="go"${VERSION}.${OS}-${ARCH}.tar.gz
BINARY_NAME="go"${VERSION}
GO_DL_URL=https://golang.org/dl/${ARCHIVE_NAME}


if [[ ! -f ${REL}/working/go/bin/go ]]; then
	curl -L ${GO_DL_URL} -o ${REL}/working/${ARCHIVE_NAME}
	cd ${REL}/working
	tar -xzf $ARCHIVE_NAME
fi

