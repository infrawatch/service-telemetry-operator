#!/bin/bash

function check_prerequisites() {
    if [ ! -f ~/.crc/pull-secret ]; then
        echo "Please create a file 'pull-secret' in ~/.crc containing the"
        echo "pull secret obtained from"
        echo "https://cloud.redhat.com/openshift/install/crc/installer-provisioned"
        echo "and try again."
        exit 1
    fi

    command -v crc >/dev/null 2>&1 || { echo >&2 "Please install crc from https://cloud.redhat.com/openshift/install/crc/installer-provisioned and restart."; exit 1; }

}

check_prerequisites
crc delete -f

# takes probably a lot shorter
sleep 60

crc setup
crc start --memory 32768 -c 8 -p ~/.crc/pull-secret

# oc startup can take some time
sleep 60

# scale up internal cluster monitoring
oc login -u kubeadmin -p `cat ~/.crc/cache/*/kubeadmin-password` https://api.crc.testing:6443
oc scale --replicas=1 statefulset --all -n openshift-monitoring; oc scale --replicas=1 deployment --all -n openshift-monitoring

cd ../deploy && ./quickstart.sh
