#!/usr/bin/env sh

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
