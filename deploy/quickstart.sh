#!/usr/bin/env bash
REL=$(dirname "$0"); source "${REL}/../build/metadata.sh"
ansible-playbook \
    --extra-vars namespace="service-telemetry" \
    --extra-vars __local_build_enabled=true \
    --extra-vars __service_telemetry_snmptraps_enabled=true \
    --extra-vars __service_telemetry_storage_ephemeral_enabled=true \
    ${REL}/../build/run-ci.yaml
