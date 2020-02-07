#!/bin/bash
REL=$(dirname "$0");
OCP_PROJECT=${OCP_PROJECT:-sa-telemetry}
QUICKSTART_CONFIG=${QUICKSTART_CONFIG:-configs/default.bash}
source "${REL}/${QUICKSTART_CONFIG}"

oc new-project "${OCP_PROJECT}"
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

---

apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: ${OCP_PROJECT}-og
  namespace: ${OCP_PROJECT}
spec:
  targetNamespaces:
  -  ${OCP_PROJECT}

---

apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: redhat-service-assurance-operators
  namespace: openshift-marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: redhat-service-assurance
  displayName: Service Assurance Operators
  publisher: Red Hat (CloudOps)

---

apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-operators
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/operator-framework/upstream-community-operators:latest
  displayName: OperatorHub.io Operators
  publisher: OperatorHub.io

---

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq7-cert-manager
  namespace: openshift-operators
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: amq7-cert-manager
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: amq7-cert-manager.v1.0.0

---

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elastic-cloud-eck
  namespace: ${OCP_PROJECT}
spec:
  channel: stable
  installPlanApproval: Automatic
  name: elastic-cloud-eck
  source: operatorhubio-operators
  sourceNamespace: openshift-marketplace
  startingCSV: elastic-cloud-eck.v1.0.0

---

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serviceassurance-operator-alpha-redhat-service-assurance-operators-openshift-marketplace
  namespace: ${OCP_PROJECT}
spec:
  channel: beta
  installPlanApproval: Automatic
  name: serviceassurance-operator
  source: redhat-service-assurance-operators
  sourceNamespace: openshift-marketplace
  startingCSV: service-assurance-operator.v0.1.1
EOF
while ! oc get csv | grep service-assurance-operator | grep Succeeded; do echo "waiting for SAO..."; sleep 3; done
if [ ! -z "${KIND_SERVICEASSURANCE}" ]; then
  oc create -f - <<< ${KIND_SERVICEASSURANCE}
fi
