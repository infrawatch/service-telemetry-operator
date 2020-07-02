#!/usr/bin/env bash
REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
TOKEN=$(oc whoami -t)
buildah login --tls-verify=false -u kubeadmin -p "${TOKEN}" "${REGISTRY}"

oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

buildah bud -f build/Dockerfile -t sto:latest
buildah tag sto:latest ${REGISTRY}/${OCP_PROJECT}/service-telemetry-operator:latest
buildah push --tls-verify=false ${REGISTRY}/${OCP_PROJECT}/service-telemetry-operator:latest
buildah rmi sto:latest

mkdir hack
pushd hack
git clone https://github.com/infrawatch/smart-gateway
git clone https://github.com/infrawatch/smart-gateway-operator

pushd smart-gateway-operator
buildah bud -f build/Dockerfile -t sgo:latest
buildah tag sgo:latest ${REGISTRY}/${OCP_PROJECT}/smart-gateway-operator:latest
buildah push --tls-verify=false ${REGISTRY}/${OCP_PROJECT}/smart-gateway-operator:latest
buildah rmi sgo:latest
popd # pop smart-gateway-operator

pushd smart-gateway
buildah bud -f Dockerfile -t sg:latest
buildah tag sg:latest ${REGISTRY}/${OCP_PROJECT}/smart-gateway:latest
buildah push --tls-verify=false ${REGISTRY}/${OCP_PROJECT}/smart-gateway:latest
buildah rmi sg:latest
popd # pop smart-gateway

popd  # pop hack

oc get imagestreams
