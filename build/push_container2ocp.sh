#!/usr/bin/env bash
#
# Pushes local container image `service-assurance-operator` into OCP
# * `oc` must already target OCP
# * container image must already be built. See build.sh for more information
#
set -e
source "$(dirname "$0")/metadata.sh"

if [ "${IMAGE_BUILDER}" = "podman" ]; then
    REG_EXTRAFLAGS="--tls-verify=false"
fi

${IMAGE_BUILDER} tag "${OPERATOR_NAME}:${IMAGE_TAG}" "${OCP_REGISTRY}/${OCP_PROJECT}/${OPERATOR_NAME}:${OCP_TAG}"
${IMAGE_BUILDER} login ${REG_EXTRAFLAGS} -u 'openshift' -p "$(oc whoami -t)" "${OCP_REGISTRY}"
${IMAGE_BUILDER} push ${REG_EXTRAFLAGS} "${OCP_REGISTRY}/${OCP_PROJECT}/${OPERATOR_NAME}"
