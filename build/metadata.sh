#!/usr/bin/env sh
#
# Source this file from other build scripts
#

# Configure these
OPERATOR_SDK=${OPERATOR_SDK:-operator-sdk}
OPERATOR_NAME=${OPERATOR_NAME:-service-telemetry-operator}
IMAGE_BUILDER=${IMAGE_BUILDER:-podman}
IMAGE_BUILD_ARGS=${IMAGE_BUILD_ARGS:-''}
IMAGE_TAG=${IMAGE_TAG:-latest}
REQUIRED_OPERATOR_SDK_VERSION=${REQUIRED_OPERATOR_SDK_VERSION:-v1.39.2}
SERVICE_TELEMETRY_SUBSCRIPTION=${SERVICE_TELEMETRY_SUBSCRIPTION:-service-telemetry-operator-stable-infrawatch-operators-openshift-marketplace}
OPERATOR_IMAGE_PULLSPEC=${OPERATOR_IMAGE_PULLSPEC:-"quay.io/infrawatch/${OPERATOR_NAME}:latest"}
OPERATOR_CSV_MAJOR_VERSION=${OPERATOR_CSV_MAJOR_VERSION:-1.5}
OPERATOR_DOCUMENTATION_URL=${OPERATOR_DOCUMENTATION_URL:-"https://infrawatch.github.io/documentation"}
CREATED_DATE=${CREATED_DATE:-$(date +'%Y-%m-%dT%H:%M:%SZ')}
RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_PULLSPEC=${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_PULLSPEC:-quay.io/infrawatch/prometheus-webhook-snmp:latest}
RELATED_IMAGE_OAUTH_PROXY_PULLSPEC=${RELATED_IMAGE_OAUTH_PROXY_PULLSPEC:-quay.io/openshift/origin-oauth-proxy:latest}
RELATED_IMAGE_PROMETHEUS_PULLSPEC=${RELATED_IMAGE_PROMETHEUS_PULLSPEC:-quay.io/prometheus/prometheus:latest}
RELATED_IMAGE_ALERTMANAGER_PULLSPEC=${RELATED_IMAGE_ALERTMANAGER_PULLSPEC:-quay.io/prometheus/alertmanager:latest}
BUNDLE_PATH=${BUNDLE_PATH:-deploy/olm-catalog/service-telemetry-operator}
BUNDLE_CHANNELS=${BUNDLE_CHANNELS:-unstable}
BUNDLE_DEFAULT_CHANNEL=${BUNDLE_DEFAULT_CHANNEL:-unstable}
OPERATOR_BUNDLE_IMAGE=${OPERATOR_BUNDLE_IMAGE:-"quay.io/infrawatch-operators/${OPERATOR_NAME}-bundle"}

# Automatic
CSV_FILE=${CSV_FILE:-"deploy/olm-catalog/${OPERATOR_NAME}/manifests/${OPERATOR_NAME}.clusterserviceversion.yaml"}
