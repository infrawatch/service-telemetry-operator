#!/usr/bin/env sh
#
# Source this file from other build scripts
#

# Configure these
OPERATOR_NAME=${OPERATOR_NAME:-service-telemetry-operator}
CSV_VERSION=${CSV_VERSION:-1.0.2}
IMAGE_BUILDER=${IMAGE_BUILDER:-podman}
IMAGE_BUILD_ARGS=${IMAGE_BUILD_ARGS:-''}
IMAGE_TAG=${IMAGE_TAG:-latest}
REQUIRED_OPERATOR_SDK_VERSION=${REQUIRED_OPERATOR_SDK_VERSION:-v0.15.2}
SERVICE_TELEMETRY_SUBSCRIPTION=${SERVICE_TELEMETRY_SUBSCRIPTION:-servicetelemetry-operator-stable-infrawatch-operators-openshift-marketplace}

# Automatic
CSV_FILE=${CSV_FILE:-"deploy/olm-catalog/${OPERATOR_NAME}/${CSV_VERSION}/${OPERATOR_NAME}.v${CSV_VERSION}.clusterserviceversion.yaml"}

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
QUICKSTART_CONFIG=${QUICKSTART_CONFIG:-configs/default.bash}
