#!/usr/bin/env bash
set -e
REL=$(dirname "$0"); source "${REL}/metadata.sh"

oc delete imagestream "${OPERATOR_NAME}" || true
oc create imagestream "${OPERATOR_NAME}"

oc delete buildconfig "${OPERATOR_NAME}" || true
oc create -f <(sed "
    s|<<OPERATOR_NAME>>|${OPERATOR_NAME}|g;
    s|<<OCP_TAG>>|${OCP_TAG}|g"\
    "buildConfig.yaml.template")

oc start-build "${OPERATOR_NAME}"

