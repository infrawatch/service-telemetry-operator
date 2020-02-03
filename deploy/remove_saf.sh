#!/bin/sh
#
# Removes SAF and (optionally) amq7 certmanager from your cluster
#
OCP_PROJECT=${OCP_PROJECT:-sa-telemetry}
REMOVE_CERTMANAGER=${REMOVE_CERTMANAGER:-true}

# The whole SAF project (start this first since it's slow)
oc delete project "${OCP_PROJECT}"

# Our custom OperatorSource
oc delete OperatorSource redhat-service-assurance-operators -n openshift-marketplace

# SAF CRDs
oc get crd | grep infra.watch | cut -d ' ' -f 1 | xargs oc delete crd

if [ "${REMOVE_CERTMANAGER}" = "true" ]; then
    # Cluster-wide certmanager subscription
    oc delete subscription amq7-cert-manager -n openshift-operators

    # Cluster-wide CSV for certmanager
    CERTMANAGER_CSV=$(oc get csv | grep amq7-cert-manager | cut -d ' ' -f 1)
    oc delete csv "${CERTMANAGER_CSV}" -n openshift-operators

    # Certmanager CRDs
    oc get crd | grep certmanager.k8s.io | cut -d ' ' -f 1 | xargs oc delete crd
fi

# Wait for namespace to actually disappear (this can take awhile)
while oc get ns "${OCP_PROJECT}" > /dev/null; do echo "Waiting for ${OCP_PROJECT} to disappear"; sleep 5; done