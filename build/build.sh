#!/usr/bin/env bash
REL=$(dirname "$0"); source "${REL}/metadata.sh"

# Get to project root to avoid
# FATA[0000] must run command in project root dir: project structure requires build/Dockerfile
cd "${REL}/.."

echo -e "\n* [info] Checking operator-sdk version\n"
SDK_VERSION=$(operator-sdk version | cut -d '"' -f2 | cut -d '-' -f1)
if [ "${SDK_VERSION}" != "${REQUIRED_OPERATOR_SDK_VERSION}" ]; then
    echo -e "* [error] Wrong operator-sdk version. Wanted ${REQUIRED_OPERATOR_SDK_VERSION}, Got: ${SDK_VERSION}\n";
    exit 1
fi

operator-sdk build "${OPERATOR_NAME}:${IMAGE_TAG}" --image-builder "${IMAGE_BUILDER}" --image-build-args "${IMAGE_BUILD_ARGS}"
