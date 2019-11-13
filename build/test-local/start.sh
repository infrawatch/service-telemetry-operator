#!/usr/bin/env bash
sed -e "s#<<CWD>>#$(pwd)#" watches.tmpl | tee watches.local
OPERATOR_NAME="Service Assurance Operator" \
WATCH_NAMESPACE="$(oc project -q)" \
ANSIBLE_VERBOSITY_SERVICEASSURANCE_INFRA_WATCH=4 \
    operator-sdk run ansible --watches-file watches.local
