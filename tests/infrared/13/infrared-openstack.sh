#!/usr/bin/env bash
set -e

# Usage:
#  VIRTHOST=my.big.hypervisor.net
#  ./infrared-openstack.sh

VIRTHOST=${VIRTHOST:-my.big.hypervisor.net}
AMQP_HOST=${AMQP_HOST:-$(oc get route -l application=qdr-white -o jsonpath='{.items[0].spec.host}')}
AMQP_PORT=${AMQP_PORT:-443}
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_rsa}"
NTP_SERVER="${NTP_SERVER:-10.35.255.6}"

VM_IMAGE_URL_PATH="${VM_IMAGE_URL_PATH:-http://127.0.0.1/my_image_location/}"
if [ "${VM_IMAGE_URL_PATH}" = "http://127.0.0.1/my_image_location/" -a -z "${VM_IMAGE}" ]; then
    echo "Please provide a VM_IMAGE_URL_PATH or VM_IMAGE"
    exit 1
fi
# Recommend these default to tested immutable dentifiers where possible, pass "latest" style ids via environment if you want them
VM_IMAGE="${VM_IMAGE:-${VM_IMAGE_URL_PATH}/rhel-guest-image-7.8-41.x86_64.qcow2}"
OSP_BUILD="${OSP_BUILD:-7.8-passed_phase2}"

infrared virsh \
    -vv \
    -o outputs/cleanup.yml \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --cleanup yes

infrared virsh \
    -vvv \
    -o outputs/provision.yml \
    --topology-nodes undercloud:1,controller:1,compute:1 \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --image-url "${VM_IMAGE}" \
    --host-memory-overcommit True \
    -e override.controller.cpu=8 \
    -e override.controller.memory=16384

infrared tripleo-undercloud \
    -vv \
    -o outputs/undercloud-install.yml \
    --mirror rdu2 \
    --version 13 \
    --build "${OSP_BUILD}" \
    --registry-mirror docker-registry.engineering.redhat.com \
    --registry-undercloud-skip no

infrared tripleo-undercloud -vv \
   -o outputs/images_settings.yml \
   --images-task rpm \
   --build "${OSP_BUILD}" \
   --images-update no

sed -e "s/<<AMQP_HOST>>/${AMQP_HOST}/;s/<<AMQP_PORT>>/${AMQP_PORT}/" stf-connectors.yaml.template > outputs/stf-connectors.yaml

infrared tripleo-overcloud \
    -vv \
    -o outputs/overcloud-install.yml \
    --version 13 \
    --deployment-files virt \
    --overcloud-debug yes \
    --network-backend vxlan \
    --network-protocol ipv4 \
    --storage-backend lvm \
    --storage-external no \
    --overcloud-ssl no \
    --tls-everywhere no \
    --network-dvr false \
    --network-lbaas false \
    --vbmc-force true \
    --introspect yes \
    --tagging yes \
    --deploy yes \
    --public-network yes \
    --public-subnet default_subnet \
    --ntp-server "${NTP_SERVER}" \
    --containers yes \
    --registry-mirror docker-registry.engineering.redhat.com \
    --overcloud-templates outputs/stf-connectors.yaml \
    --registry-undercloud-skip no
