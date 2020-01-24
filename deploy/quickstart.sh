#!/bin/bash
SAF_PROJECT=${SAF_PROJECT:-sa-telemetry}
SAF_CONFIG=${SAF_CONFIG:-configs/default.bash}
source ${SAF_CONFIG}

oc new-project "${SAF_PROJECT}"
oc create -f - <<EOF
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

apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: ${SAF_PROJECT}-og
  namespace: ${SAF_PROJECT}
spec:
  targetNamespaces:
  -  ${SAF_PROJECT}

---

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serviceassurance-operator-alpha-redhat-service-assurance-operators-openshift-marketplace
  namespace: ${SAF_PROJECT}
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: serviceassurance-operator
  source: redhat-service-assurance-operators
  sourceNamespace: openshift-marketplace
  startingCSV: service-assurance-operator.v0.1.0
EOF
while ! oc get csv | grep service-assurance-operator | grep Succeeded; do echo "waiting for SAO..."; sleep 3; done
oc create -f - <<EOF
${KIND_SERVICEASSURANCE}
EOF
