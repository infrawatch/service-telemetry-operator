#!/usr/bin/env sh
#
# Source this file from other build scripts
#

# Configure these
OPERATOR_SDK=${OPERATOR_SDK:-operator-sdk}
OPERATOR_NAME=${OPERATOR_NAME:-service-telemetry-operator}
IMAGE_BUILDER=${IMAGE_BUILDER:-podman}
IMAGE_BUILD_ARGS=${IMAGE_BUILD_ARGS:-''}
IMAGE_TAG=${IMAGE_TAG:-stable-1.5}
REQUIRED_OPERATOR_SDK_VERSION=${REQUIRED_OPERATOR_SDK_VERSION:-v0.19.4}
SERVICE_TELEMETRY_SUBSCRIPTION=${SERVICE_TELEMETRY_SUBSCRIPTION:-service-telemetry-operator-stable-infrawatch-operators-openshift-marketplace}
OPERATOR_IMAGE=${OPERATOR_IMAGE:-"quay.io/infrawatch/${OPERATOR_NAME}"}
OPERATOR_TAG=${OPERATOR_TAG:-stable-1.5}
OPERATOR_CSV_MAJOR_VERSION=${OPERATOR_CSV_MAJOR_VERSION:-1.5}
OPERATOR_DOCUMENTATION_URL=${OPERATOR_DOCUMENTATION_URL:-"https://infrawatch.github.io/documentation"}
BUNDLE_OLM_SKIP_RANGE_LOWER_BOUND=${BUNDLE_OLM_SKIP_RANGE_LOWER_BOUND:-1.3.0}
CREATED_DATE=${CREATED_DATE:-$(date +'%Y-%m-%dT%H:%M:%SZ')}
RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP=${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP:-quay.io/infrawatch/prometheus-webhook-snmp}
RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_TAG=${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_TAG:-stable-1.5}
RELATED_IMAGE_OAUTH_PROXY=${RELATED_IMAGE_OAUTH_PROXY:-quay.io/openshift/origin-oauth-proxy}
RELATED_IMAGE_OAUTH_PROXY_TAG=${RELATED_IMAGE_OAUTH_PROXY_TAG:-latest}
BUNDLE_PATH=${BUNDLE_PATH:-deploy/olm-catalog/service-telemetry-operator}
BUNDLE_CHANNELS=${BUNDLE_CHANNELS:-stable-1.5}
BUNDLE_DEFAULT_CHANNEL=${BUNDLE_DEFAULT_CHANNEL:-stable-1.5}
OPERATOR_BUNDLE_IMAGE=${OPERATOR_BUNDLE_IMAGE:-"quay.io/infrawatch-operators/${OPERATOR_NAME}-bundle"}

# Automatic
CSV_FILE=${CSV_FILE:-"deploy/olm-catalog/${OPERATOR_NAME}/manifests/${OPERATOR_NAME}.clusterserviceversion.yaml"}
