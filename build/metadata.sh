#!/usr/bin/env sh
#
# Source this file from other build scripts
#

# Configure these
OPERATOR_NAME=${OPERATOR_NAME:-service-telemetry-operator}
IMAGE_BUILDER=${IMAGE_BUILDER:-podman}
IMAGE_BUILD_ARGS=${IMAGE_BUILD_ARGS:-''}
IMAGE_TAG=${IMAGE_TAG:-latest}
REQUIRED_OPERATOR_SDK_VERSION=${REQUIRED_OPERATOR_SDK_VERSION:-v0.19.4}
SERVICE_TELEMETRY_SUBSCRIPTION=${SERVICE_TELEMETRY_SUBSCRIPTION:-service-telemetry-operator-stable-infrawatch-operators-openshift-marketplace}
OPERATOR_IMAGE=${OPERATOR_IMAGE:-"quay.io/infrawatch/${OPERATOR_NAME}"}
OPERATOR_TAG=${OPERATOR_TAG:-latest}
OPERATOR_CSV_MAJOR_VERSION=${OPERATOR_CSV_MAJOR_VERSION:-1.3}
CREATED_DATE=${CREATED_DATE:-$(date +'%Y-%m-%dT%H:%M:%SZ')}
RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP=${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP:-quay.io/infrawatch/prometheus-webhook-snmp}
RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_TAG=${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_TAG:-latest}
BUNDLE_PATH=${BUNDLE_PATH:-deploy/olm-catalog/service-telemetry-operator}

# Automatic
CSV_FILE=${CSV_FILE:-"deploy/olm-catalog/${OPERATOR_NAME}/manifests/${OPERATOR_NAME}.clusterserviceversion.yaml"}

# Vars below here are for LOCAL DEV ONLY
#
# NOTE: Strongly suggest that the destination tag in OCP is "latest" for testing
# purposes, otherwise additional procedures are required to force a pull of an
# updated container image
OCP_PROJECT=${OCP_PROJECT:-service-telemetry}
OCP_REGISTRY=${OCP_REGISTRY:-$(oc registry info)}
OCP_REGISTRY_INTERNAL=${OCP_REGISTRY_INTERNAL:-$(oc registry info --internal=true)}
OCP_TAG=${OCP_TAG:-latest}
OCP_USER=${OCP_USER:-openshift}
