#!/usr/bin/env bash
set -e

# Usage:
#  VIRTHOST=my.big.hypervisor.net
#  ./infrared-openstack.sh

VIRTHOST=${VIRTHOST:-localhost}
AMQP_HOST=${AMQP_HOST:-stf-default-interconnect-5671-service-telemetry.apps-crc.testing}
AMQP_PORT=${AMQP_PORT:-443}
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_rsa}"
NTP_SERVER="${NTP_SERVER:-clock.redhat.com,10.5.27.10,10.11.160.238}"

VM_IMAGE_URL_PATH="${VM_IMAGE_URL_PATH:-http://download.eng.bos.redhat.com/brewroot/packages/rhel-guest-image/8.1/333/images}"
# Recommend these default to tested immutable dentifiers where possible, pass "latest" style ids via environment if you want them
VM_IMAGE="${VM_IMAGE:-rhel-guest-image-8.1-333.x86_64.qcow2}"
VM_IMAGE_LOCATION="${VM_IMAGE_URL_PATH}/${VM_IMAGE}"

OSP_BUILD="${OSP_BUILD:-RHOS_TRUNK-16.0-RHEL-8-20200406.n.1}"
OSP_VERSION="${OSP_VERSION:-16}"
OSP_TOPOLOGY="${OSP_TOPOLOGY:-undercloud:1,controller:1,compute:1,ceph:1}"
OSP_MIRROR="${OSP_MIRROR:-rdu2}"
LIBVIRT_DISKPOOL="${LIBVIRT_DISKPOOL:-/var/lib/libvirt/images}"

infrared virsh \
    -vv \
    -o outputs/cleanup.yml \
    --disk-pool "${LIBVIRT_DISKPOOL}" \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --cleanup yes

infrared virsh \
    -vvv \
    -o outputs/provision.yml \
    --disk-pool /home/libvirt/images \
    --topology-nodes "${OSP_TOPOLOGY}" \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --image-url "${VM_IMAGE_LOCATION}" \
    --host-memory-overcommit True \
    -e override.controller.cpu=8 \
    -e override.controller.memory=32768 \
    --serial-files True

infrared tripleo-undercloud \
    -vv \
    -o outputs/undercloud-install.yml \
    --mirror "${OSP_MIRROR}" \
    --version ${OSP_VERSION} \
    --build "${OSP_BUILD}" \
    --images-task rpm \
    --images-update no \
    --tls-ca https://password.corp.redhat.com/RH-IT-Root-CA.crt \
    --config-options DEFAULT.undercloud_timezone=UTC

sed -e "s/<<AMQP_HOST>>/${AMQP_HOST}/;s/<<AMQP_PORT>>/${AMQP_PORT}/" metrics-qdr-connectors.yaml.template > outputs/metrics-qdr-connectors.yaml

infrared tripleo-overcloud \
    -vv \
    -o outputs/overcloud-install.yml \
    --version ${OSP_VERSION} \
    --deployment-files virt \
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
    --containers yes \
    --overcloud-templates outputs/metrics-qdr-connectors.yaml

infrared tempest \
	-vv \
    -o outputs/test.yml \
    --openstack-installer tripleo \
    --openstack-version "${OSP_VERSION}" \
    --tests smoke \
    --setup rpm \
    --revision=HEAD \
    --image http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
