#!/usr/bin/env bash
REL=$(dirname "$0"); source "${REL}/../build/metadata.sh"

oc new-project "${OCP_PROJECT}"
ansible-playbook \
    --extra-vars namespace="${OCP_PROJECT}" \
    --extra-vars __local_build_enabled=false \
    ${REL}/../build/run-ci.yaml
