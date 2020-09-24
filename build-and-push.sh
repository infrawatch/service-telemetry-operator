#!/bin/bash

eval $(crc console --credentials | grep "admin, run" | cut -f2 -d"'") --insecure-skip-tls-verify=true


REGISTRY=$(oc registry info)
TOKEN=$(oc whoami -t)
INTERNAL_REGISTRY=$(oc registry info --internal=true)
buildah login --tls-verify=false -u openshift -p "${TOKEN}" "${REGISTRY}"
buildah bud -f build/Dockerfile -t "${REGISTRY}/service-telemetry/service-telemetry-operator:latest" .
buildah push --tls-verify=false "${REGISTRY}/service-telemetry/service-telemetry-operator:latest"

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: smartgateway-operator
  namespace: service-telemetry
spec:
  channel: stable
  installPlanApproval: Automatic
  name: smartgateway-operator
  source: infrawatch-operators
  sourceNamespace: openshift-marketplace
  startingCSV: smart-gateway-operator.v2.0.0
EOF

oc delete servicetelemetry stf-default

CSV_VERSION=1.1.0

oc delete csv service-telemetry-operator-v${CSV_VERSION}

oc apply \
    -f deploy/role_binding.yaml \
    -f deploy/role.yaml \
    -f deploy/service_account.yaml \
    -f deploy/operator_group.yaml

oc apply -f deploy/olm-catalog/service-telemetry-operator/${CSV_VERSION}/infra.watch_servicetelemetrys_crd.yaml
oc apply -f <(sed "\
    s|image: .\+/service-telemetry-operator:.\+$|image: ${INTERNAL_REGISTRY}/service-telemetry/service-telemetry-operator:latest|g;
    s|namespace: placeholder|namespace: service-telemetry|g"\
    "deploy/olm-catalog/service-telemetry-operator/${CSV_VERSION}/service-telemetry-operator.v${CSV_VERSION}.clusterserviceversion.yaml")

oc apply -f - <<EOF
apiVersion: infra.watch/v1alpha1
kind: ServiceTelemetry
metadata:
  name: stf-default
  namespace: service-telemetry
spec:
  highAvailabilityEnabled: false
  eventsEnabled: true
  metricsEnabled: true
  storageEphemeralEnabled: false
  snmpTrapsEnabled: true
  snmpTrapsTarget: "192.168.36.9"
EOF
