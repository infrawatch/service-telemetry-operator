#!/bin/sh
#
# Removes SAF and amq7 cert manager from your cluster
#
SAF_PROJECT=${SAF_PROJECT:-sa-telemetry}

# The whole SAF project
oc delete project "${SAF_PROJECT}"

# Our custom OperatorSource
oc delete OperatorSource redhat-service-assurance-operators -n openshift-marketplace

# Cluster-wide cert manager subscription
oc delete subscription amq7-cert-manager -n openshift-operators

# Cluster-wide CSV for cert manager
CERTMANAGER_CSV=$(oc get csv | grep amq7-cert-manager | cut -d ' ' -f 1)
oc delete csv "${CERTMANAGER_CSV}" -n openshift-operators

# CRDs which get left behind
oc get crd | grep infra.watch | cut -d ' ' -f 1 | xargs oc delete crd
oc get crd | grep certmanager.k8s.io | cut -d ' ' -f 1 | xargs oc delete crd

# Wait for namespace to actually disappear (this can take awhile)
while oc get ns "${SAF_PROJECT}" > /dev/null; do echo "Waiting for ${SAF_PROJECT} to disappear"; sleep 5; done