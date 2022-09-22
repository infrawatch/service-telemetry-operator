#!/bin/sh
#
# Removes STF and (optionally) Cert-Manager For OpenShift from your cluster
#
REL=$(dirname "$0"); . "${REL}/../build/metadata.sh"
REMOVE_CERTMANAGER=${REMOVE_CERTMANAGER:-true}

# The whole STF project (start this first since it's slow)
oc delete project "${OCP_PROJECT}"

# Our custom OperatorSource
oc delete OperatorSource infrawatch-operators -n openshift-marketplace

# Revert our OperatorHub.io catalog for default built-in Community Operators
oc delete CatalogSource operatorhubio-operators -n openshift-marketplace

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OperatorHub
metadata:
  name: cluster
spec:
  disableAllDefaultSources: true
  sources:
  - disabled: false
    name: certified-operators
  - disabled: false
    name: redhat-operators
  - disabled: false
    name: community-operators
EOF

# STF CRDs
oc get crd | grep infra.watch | cut -d ' ' -f 1 | xargs oc delete crd

if [ "${REMOVE_CERTMANAGER}" = "true" ]; then
    # Cluster-wide certmanager subscription
    oc delete subscription amq7-cert-manager -n openshift-operators

    # Cluster-wide CSV for certmanager
    CERTMANAGER_CSV=$(oc get csv | grep amq7-cert-manager | cut -d ' ' -f 1)
    oc delete csv "${CERTMANAGER_CSV}" -n openshift-operators

    # Certmanager CRDs
    oc get crd | grep cert-manager.io | cut -d ' ' -f 1 | xargs oc delete crd
fi

# Wait for namespace to actually disappear (this can take awhile)
while oc get ns "${OCP_PROJECT}" > /dev/null; do echo "Waiting for ${OCP_PROJECT} to disappear"; sleep 5; done

for i in $(oc get images | grep "${OCP_PROJECT}" | cut -f1 -d' '); do oc delete image $i; done
