#!/bin/env bash
LOCAL_TUNNEL_PORT="${LOCAL_TUNNEL_PORT:-8787}"

# Install minishift on $VIRTHOST
scp -r baremetal-scripts/ "root@${VIRTHOST}:"
ssh "root@${VIRTHOST}" ./baremetal-scripts/install-and-run-minishift.sh

# Get a functioning kubeconfig for the minishift instance
KUBECONFIG="$(pwd)/outputs/kubeconfig-${VIRTHOST}"
scp "root@${VIRTHOST}:.kube/config" "${KUBECONFIG}"


# Tunnel the k8s API port
MINISHIFT_HOST_PORT=$(grep server "${KUBECONFIG}" | awk -F '://' '{print $2}')
ssh -N -L "${LOCAL_TUNNEL_PORT}:${MINISHIFT_HOST_PORT}" "root@${VIRTHOST}" &
sed -i.orig -e "s#https://${MINISHIFT_HOST_PORT}#https://localhost:${LOCAL_TUNNEL_PORT}#" "${KUBECONFIG}"

# Switch to tunneled minishift context
export KUBECONFIG

pushd .
cd ../../deploy/
./quickstart.sh

cd ../tests
./smoketest.sh
popd