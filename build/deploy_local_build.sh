#!/usr/bin/env bash
#
# Deploys SAO into the cluster via a CSV pointing to a local SAO image build.
#
# Build is assumed to be available as `$OCP_PROJECT/$OPERATOR_NAME`
# in the OCP registry. See build/push_container2ocp.sh for more information
#
set -e
REL=$(dirname "$0"); source "${REL}/metadata.sh"

# Do a partial SAO uninstall (non-DRY/generic name, matches quickstart manifest)
oc delete sub servicetelemetry-operator-beta-infrawatch-operators-openshift-marketplace || true
oc delete csv "${OPERATOR_NAME}.v${CSV_VERSION}" || true

# RBAC is handled by the subscription controller
# But we are installing directly from a csv so we have to do it ourselves
oc create -f "${REL}/../deploy/service_account.yaml"
oc create -f "${REL}/../deploy/role.yaml"
oc create -f "${REL}/../deploy/role_binding.yaml"

# Mutate the CSV to pull the image from the OCP registry and install it
oc create -f <(sed "\
    s|image: .\+/${OPERATOR_NAME}:.\+$|image: ${OCP_REGISTRY_INTERNAL}/${OCP_PROJECT}/${OPERATOR_NAME}:${OCP_TAG}|g;
    s|namespace: placeholder|namespace: ${OCP_PROJECT}|g"\
    "${REL}/../${CSV_FILE}")
