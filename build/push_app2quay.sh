#!/usr/bin/env bash
# contents of this file originally from https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/openshift-deployment

set -e

CSV_VERSION=${1:-0.1.0}
UNIXDATE=$(date +%s)

echo -n "Username: "
read USERNAME
echo -n "Password: "
read -s PASSWORD
echo

AUTH_TOKEN=$(curl -sH "Content-Type: application/json" \
-XPOST https://quay.io/cnr/api/v1/users/login \
-d '{"user": {"username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'"}}' | jq -r '.token')

operator-courier push "./deploy/olm-catalog/service-assurance-operator" "redhat-service-assurance" "service-assurance-operator" "${CSV_VERSION}-${UNIXDATE}" "${AUTH_TOKEN}"
# vim: set ft=bash:
