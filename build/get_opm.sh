#!/bin/bash

set -x

REL=$(dirname "$0")
VERSION="$1"
OPM_DL_URL=https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}

if [[ ! -f ${REL}/working/opm ]]; then
	mkdir -p ${REL}/working
	curl -L ${OPM_DL_URL}/opm-linux.tar.gz -o ${REL}/working/opm
	chmod +x ${REL}/working/opm
	rm -f ${REL}/working/opm-linux.tar.gz
fi

set +x