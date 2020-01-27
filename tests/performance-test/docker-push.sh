#!/bin/bash

#Automates creating and pushing new performance test image to openshift registry
PROJECT="$(oc project -q)"
DOCKER_IMAGE="$(oc get route docker-registry -n default -o jsonpath='{.spec.host}')/${PROJECT}/performance-test:dev"

docker build -t "$DOCKER_IMAGE" .

oc delete is performance-test:dev
docker push "$DOCKER_IMAGE"

