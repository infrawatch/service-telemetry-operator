#!/bin/bash

oc delete \
   deployment/promxy \
   configmap/promxy-config

oc create -f promxy-manifests.yaml

oc rollout status deployment/promxy
