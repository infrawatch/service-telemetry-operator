#!/usr/bin/env sh
#
# Source this file from other build scripts
#

# Configure these
OPERATOR_NAME=${OPERATOR_NAME:-service-assurance-operator}
CSV_VERSION=${CSV_VERSION:-0.1.1}
IMAGE_BUILDER=${IMAGE_BUILDER:-podman}
IMAGE_TAG=${IMAGE_TAG:-latest}
REQUIRED_OPERATOR_SDK_VERSION=${REQUIRED_OPERATOR_SDK_VERSION:-v0.12.0}

# Automatic
CSV_FILE=${CSV_FILE:-"deploy/olm-catalog/${OPERATOR_NAME}/${CSV_VERSION}/${OPERATOR_NAME}.v${CSV_VERSION}.clusterserviceversion.yaml"}

# Vars below here are for LOCAL DEV ONLY
#
# NOTE: Strongly suggest that the destination tag in OCP is "latest" for testing
# purposes, otherwise additional procedures are required to force a pull of an
# updated container image
OCP_TAG=${OCP_TAG:-latest}
OCP_REGISTRY=${OCP_REGISTRY:-$(oc registry info)}
OCP_REGISTRY_INTERNAL=${OCP_REGISTRY_INTERNAL:-$(oc registry info --internal=true)}
OCP_PROJECT=${OCP_PROJECT:-sa-telemetry}
