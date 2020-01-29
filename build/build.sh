#!/usr/bin/env bash
REL=$(dirname "$0"); source "${REL}/metadata.sh"

# Get to project root to avoid
# FATA[0000] must run command in project root dir: project structure requires build/Dockerfile
cd "${REL}/.."

operator-sdk build "${OPERATOR_NAME}:${IMAGE_TAG}" --image-builder "${IMAGE_BUILDER}"
