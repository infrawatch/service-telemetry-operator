#!/usr/bin/env bash
set -e

# Usage:
#  VIRTHOST=my.big.hypervisor.net
#  ./infrared-openstack.sh

VIRTHOST=${VIRTHOST:-localhost}
AMQP_HOST=${AMQP_HOST:-saf-default-interconnect-5671-sa-telemetry.apps-crc.testing}
AMQP_PORT=${AMQP_PORT:-443}
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_rsa}"
VM_IMAGE="${VM_IMAGE:-http://download.devel.redhat.com/brewroot/packages/rhel-guest-image/8.1/333/images/rhel-guest-image-8.1-333.x86_64.qcow2}"
OSP_BUILD="${OSP_BUILD:-latest-RHOS_TRUNK-16-RHEL-8.1}"
NTP_SERVER="${NTP_SERVER:-clock.redhat.com,10.5.27.10,10.11.160.238}"

infrared virsh \
    -vv \
    -o outputs/cleanup.yml \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --cleanup yes

infrared virsh \
    -vvv \
    -o outputs/provision.yml \
    --topology-nodes undercloud:1,controller:1,compute:1,ceph:1 \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --image-url "${VM_IMAGE}" \
    --host-memory-overcommit True \
    -e override.controller.cpu=8 \
    -e override.controller.memory=32768 \
    --serial-files True

infrared tripleo-undercloud \
    -vv \
    -o outputs/undercloud-install.yml \
    --mirror rdu2 \
    --version 16 \
    --build "${OSP_BUILD}" \
    --images-task rpm \
    --images-update no \
    --tls-ca https://password.corp.redhat.com/RH-IT-Root-CA.crt \
    --config-options DEFAULT.undercloud_timezone=UTC

sed -e "s/<<AMQP_HOST>>/${AMQP_HOST}/;s/<<AMQP_PORT>>/${AMQP_PORT}/" metrics-collectd-qdr.yaml.template > outputs/metrics-collectd-qdr.yaml

infrared tripleo-overcloud \
    -vv \
    -o outputs/overcloud-install.yml \
    --version 16 \
    --deployment-files virt \
    --overcloud-templates="none" \
    --overcloud-debug yes \
    --network-backend geneve \
    --network-protocol ipv4 \
    --network-dvr yes \
    --storage-backend ceph \
    --storage-external no \
    --overcloud-ssl no \
    --introspect yes \
    --tagging yes \
    --deploy yes \
    --ntp-server ${NTP_SERVER} \
    --containers yes
