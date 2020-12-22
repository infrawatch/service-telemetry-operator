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
CLOUD_NAME="${CLOUD_NAME:-sample}"

VM_IMAGE_URL_PATH="${VM_IMAGE_URL_PATH:-http://download.devel.redhat.com/rhel-8/rel-eng/RHEL-8/latest-RHEL-8.2.0/compose/BaseOS/x86_64/images/}"
# Recommend these default to tested immutable dentifiers where possible, pass "latest" style ids via environment if you want them
VM_IMAGE="${VM_IMAGE:-rhel-guest-image-8.2-290.x86_64.qcow2}"
VM_IMAGE_LOCATION="${VM_IMAGE_URL_PATH}/${VM_IMAGE}"

OSP_BUILD="${OSP_BUILD:-passed_phase2}"
OSP_VERSION="${OSP_VERSION:-16.1}"
OSP_TOPOLOGY="${OSP_TOPOLOGY:-undercloud:1,controller:3,compute:2,ceph:3}"
OSP_MIRROR="${OSP_MIRROR:-rdu2}"
LIBVIRT_DISKPOOL="${LIBVIRT_DISKPOOL:-/var/lib/libvirt/images}"
ENVIRONMENT_TEMPLATE="${ENVIRONMENT_TEMPLATE:-stf-connectors.yaml.template}"
OVERCLOUD_DOMAIN="${OVERCLOUD_DOMAIN:-`hostname -s`}"

TEMPEST_ONLY="${TEMPEST_ONLY:-false}"
RUN_WORKLOAD="${RUN_WORKLOAD:-false}"
ENABLE_STF_CONNECTORS="${ENABLE_STF_CONNECTORS:-true}"

ir_run_cleanup() {
  infrared virsh \
      -vv \
      -o outputs/cleanup.yml \
      --disk-pool "${LIBVIRT_DISKPOOL}" \
      --host-address "${VIRTHOST}" \
      --host-key "${SSH_KEY}" \
      --cleanup yes
}

ir_run_provision() {
  infrared virsh \
      -vvv \
      -o outputs/provision.yml \
      --disk-pool "${LIBVIRT_DISKPOOL}" \
      --topology-nodes "${OSP_TOPOLOGY}" \
      --host-address "${VIRTHOST}" \
      --host-key "${SSH_KEY}" \
      --image-url "${VM_IMAGE_LOCATION}" \
      --host-memory-overcommit True \
      -e override.controller.cpu=4 \
      -e override.controller.memory=16384 \
      --serial-files True
}

ir_create_undercloud() {
  infrared tripleo-undercloud \
      -vv \
      -o outputs/undercloud-install.yml \
      --mirror "${OSP_MIRROR}" \
      --version "${OSP_VERSION}" \
      --build "${OSP_BUILD}" \
      --images-task rpm \
      --images-update no \
      --tls-ca https://password.corp.redhat.com/RH-IT-Root-CA.crt \
      --overcloud-domain "${OVERCLOUD_DOMAIN}" \
      --config-options DEFAULT.undercloud_timezone=UTC
}

stf_create_config() {
  sed -e "s/<<AMQP_HOST>>/${AMQP_HOST}/;s/<<AMQP_PORT>>/${AMQP_PORT}/;s/<<CLOUD_NAME>>/${CLOUD_NAME}/" ${ENVIRONMENT_TEMPLATE} > outputs/stf-connectors.yaml
}

ir_create_overcloud() {
  infrared tripleo-overcloud \
      -vv \
      -o outputs/overcloud-install.yml \
      --version "${OSP_VERSION}" \
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
      --ntp-server "${NTP_SERVER}" \
      --overcloud-templates outputs/stf-connectors.yaml \
      --overcloud-domain "${OVERCLOUD_DOMAIN}" \
      --containers yes
}

ir_run_tempest() {
  infrared tempest \
      -vv \
      -o outputs/test.yml \
      --openstack-installer tripleo \
      --openstack-version "${OSP_VERSION}" \
      --tests smoke \
      --setup rpm \
      --revision=HEAD \
      --image http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
}

ir_expose_ui() {
  infrared cloud-config --deployment-files virt --tasks create_external_network,forward_overcloud_dashboard
}

ir_run_workload() {
    infrared cloud-config --deployment-files virt --tasks launch_workload
}

time if ${TEMPEST_ONLY}; then
  echo "-- Running tempest tests"
  ir_run_tempest
else
  echo "-- full cloud deployment"
  echo ">> Cloud name: ${CLOUD_NAME}"
  echo ">> Overcloud domain: ${OVERCLOUD_DOMAIN}"
  echo ">> STF enabled: ${ENABLE_STF_CONNECTORS}"
  echo ">> OSP version: ${OSP_VERSION}"
  echo ">> OSP build: ${OSP_BUILD}"
  echo ">> OSP topology: ${OSP_TOPOLOGY}"

  ir_run_cleanup
  ir_run_provision
  ir_create_undercloud
  if ${ENABLE_STF_CONNECTORS}; then
    stf_create_config
  else
    touch outputs/stf-connectors.yaml
    truncate --size 0 outputs/stf-connectors.yaml
  fi
  ir_create_overcloud
  ir_expose_ui
  if ${RUN_WORKLOAD}; then
    ir_run_workload
  fi

  echo "-- deployment completed"
  echo ">> Cloud name: ${CLOUD_NAME}"
  echo ">> Overcloud domain: ${OVERCLOUD_DOMAIN}"
  echo ">> STF enabled: ${ENABLE_STF_CONNECTORS}"
  echo ">> OSP version: ${OSP_VERSION}"
  echo ">> OSP build: ${OSP_BUILD}"
  echo ">> OSP topology: ${OSP_TOPOLOGY}"
fi


