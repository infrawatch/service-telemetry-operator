#!/usr/bin/env bash
REL=$(dirname "$0"); source "${REL}/../build/metadata.sh"
EPHEMERAL_STORAGE="${EPHEMERAL_STORAGE:-true}"
OCP_PROJECT=service-telemetry

oc new-project "${OCP_PROJECT}"
ansible-playbook \
    --extra-vars namespace="${OCP_PROJECT}" \
    --extra-vars __local_build_enabled=true \
    --extra-vars __service_telemetry_snmptraps_enabled=true \
    --extra-vars __service_telemetry_storage_ephemeral_enabled=${EPHEMERAL_STORAGE} \
    -vvv \
    ${REL}/../build/run-ci.yaml
