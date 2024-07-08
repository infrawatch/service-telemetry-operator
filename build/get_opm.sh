#!/bin/bash

set -x

REL=$(dirname "$0")
VERSION="$1"
OPM_DL_URL=https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}

if [[ ! -f ${REL}/working/opm-${VERSION} ]]; then
	mkdir -p ${REL}/working
	curl -L ${OPM_DL_URL}/opm-linux-${VERSION}.tar.gz -o ${REL}/working/opm-${VERSION}
	chmod +x ${REL}/working/opm-${VERSION}
	rm -f ${REL}/working/opm-linux-${VERSION}.tar.gz
fi

set +x