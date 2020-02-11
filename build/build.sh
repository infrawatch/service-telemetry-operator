#!/usr/bin/env bash
set -e
REL=$(dirname "$0"); source "${REL}/metadata.sh"

oc create imagestream "${OPERATOR_NAME}" || true

oc apply -f <(sed "
    s|<<OPERATOR_NAME>>|${OPERATOR_NAME}|g;
    s|<<OCP_TAG>>|${OCP_TAG}|g"\
    "${REL}/buildConfig.yaml.template")

oc start-build "${OPERATOR_NAME}" --wait --follow --from-repo "${REL}/.."