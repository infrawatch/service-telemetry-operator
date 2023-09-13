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
CLOUD_NAME="${CLOUD_NAME:-cloud1}"
OCP_ROUTE_IP=${OCP_ROUTE_IP:-}

VM_IMAGE_URL_PATH="${VM_IMAGE_URL_PATH:-http://download.devel.redhat.com/rhel-9/rel-eng/RHEL-9/latest-RHEL-9.2/compose/BaseOS/x86_64/images/}"
# Recommend these default to tested immutable dentifiers where possible, pass "latest" style ids via environment if you want them
VM_IMAGE="${VM_IMAGE:-rhel-guest-image-9.2-20230414.17.x86_64.qcow2}"
VM_IMAGE_LOCATION="${VM_IMAGE_URL_PATH}/${VM_IMAGE}"

OSP_BUILD="${OSP_BUILD:-passed_phase2}"
OSP_VERSION="${OSP_VERSION:-17.1}"
OSP_TOPOLOGY="${OSP_TOPOLOGY:-undercloud:1,controller:3,compute:2,ceph:0}"
OSP_MIRROR="${OSP_MIRROR:-rdu2}"
LIBVIRT_DISKPOOL="${LIBVIRT_DISKPOOL:-/var/lib/libvirt/images}"
STF_ENVIRONMENT_TEMPLATE="${STF_ENVIRONMENT_TEMPLATE:-stf-connectors.yaml.template}"
GNOCCHI_ENVIRONMENT_TEMPLATE="${GNOCCHI_ENVIRONMENT_TEMPLATE:-gnocchi-connectors.yaml.template}"
ENABLE_STF_ENVIRONMENT_TEMPLATE="${ENABLE_STF_ENVIRONMENT_TEMPLATE:-enable-stf.yaml.template}"
EXTRA_HOST_FILE_TEMPLATE="${EXTRA_HOST_FILE_TEMPLATE:-extra-hosts.yaml.template}"
OVERCLOUD_DOMAIN="${OVERCLOUD_DOMAIN:-`hostname -s`}"

UNDERCLOUD_CPU="${UNDERCLOUD_CPU:-4}"
UNDERCLOUD_MEMORY="${UNDERCLOUD_MEMORY:-16384}"
CONTROLLER_CPU="${CONTROLLER_CPU:-2}"
CONTROLLER_MEMORY="${CONTROLLER_MEMORY:-12228}"
COMPUTE_CPU="${COMPUTE_CPU:-4}"
COMPUTE_MEMORY="${COMPUTE_MEMORY:-12228}"
CEPH_CPU="${CEPH_CPU:-2}"
CEPH_MEMORY="${CEPH_MEMORY:-4096}"

TEMPEST_ONLY="${TEMPEST_ONLY:-false}"
RUN_WORKLOAD="${RUN_WORKLOAD:-false}"
CA_CERT_FILE_CONTENT="${CA_CERT_FILE_CONTENT:-}"
ENABLE_STF_CONNECTORS="${ENABLE_STF_CONNECTORS:-true}"
ENABLE_GNOCCHI_CONNECTORS="${ENABLE_GNOCCHI_CONNECTORS:-true}"

ir_run_cleanup() {
  infrared virsh \
      -vv \
      -o outputs/cleanup.yml \
      --disk-pool "${LIBVIRT_DISKPOOL}" \
      --host-address "${VIRTHOST}" \
      --host-key "${SSH_KEY}" \
      --cleanup yes

  echo "*** If you just want to clean up the environment now is your chance to Ctrl+C ***"
  sleep 10
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
      --topology-network 3_nets \
      -e override.undercloud.cpu="${UNDERCLOUD_CPU}" \
      -e override.undercloud.memory="${UNDERCLOUD_MEMORY}" \
      -e override.controller.cpu="${CONTROLLER_CPU}" \
      -e override.controller.memory="${CONTROLLER_MEMORY}" \
      -e override.compute.cpu="${COMPUTE_CPU}" \
      -e override.compute.memory="${COMPUTE_MEMORY}" \
      -e override.ceph.cpu="${CEPH_CPU}" \
      -e override.ceph.memory="${CEPH_MEMORY}" \
      --serial-files True \
      --bootmode uefi
}

ir_create_undercloud() {
  infrared tripleo-undercloud \
      -vv \
      -o outputs/undercloud-install.yml \
      --mirror "${OSP_MIRROR}" \
      --version "${OSP_VERSION}" \
      --splitstack no \
      --shade-host undercloud-0 \
      --ssl yes \
      --build "${OSP_BUILD}" \
      --images-task rpm \
      --images-update no \
      --tls-ca https://password.corp.redhat.com/RH-IT-Root-CA.crt \
      --overcloud-domain "${OVERCLOUD_DOMAIN}" \
      --config-options DEFAULT.undercloud_timezone=UTC
}

stf_create_config() {
  sed -r "s/<<AMQP_HOST>>/${AMQP_HOST}/;s/<<AMQP_PORT>>/${AMQP_PORT}/;s/<<CLOUD_NAME>>/${CLOUD_NAME}/;s%<<CA_CERT_FILE_CONTENT>>%${CA_CERT_FILE_CONTENT//$'\n'/<@@@>}%;s/<@@@>/\n                /g" ${STF_ENVIRONMENT_TEMPLATE} > outputs/stf-connectors.yaml
}

gnocchi_create_config() {
  cat ${GNOCCHI_ENVIRONMENT_TEMPLATE} > outputs/gnocchi-connectors.yaml
}

enable_stf_create_config() {
  cat ${ENABLE_STF_ENVIRONMENT_TEMPLATE} > outputs/enable-stf.yaml
}

enable_extra_host_file_create_config() {
  sed -r "s/<<EXTRA_HOST_FILE_ENTRIES>>/${OCP_ROUTE_IP} ${AMQP_HOST}/g" ${EXTRA_HOST_FILE_TEMPLATE} > outputs/extra-hosts.yaml
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
      --network-bgpvpn no \
      --network-dvr no \
      --network-l2gw no \
      --storage-backend lvm \
      --overcloud-ssl no \
      --introspect yes \
      --tagging yes \
      --deploy yes \
      --overcloud-templates ceilometer-write-qdr-edge-only,outputs/enable-stf.yaml,outputs/stf-connectors.yaml,outputs/gnocchi-connectors.yaml,outputs/extra-hosts.yaml \
      --overcloud-domain "${OVERCLOUD_DOMAIN}" \
      --containers yes \
      --vbmc-force False \
      --vbmc-host undercloud \
      --config-heat ComputeParameters.NeutronBridgeMappings='tenant:br-isolated' \
      --extra-vars osp_version="${OSP_VERSION}"
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
  infrared cloud-config --external-dhcp True \
                        --external-shared True \
                        --deployment-files virt \
                        --tasks create_external_network,forward_overcloud_dashboard
}

ir_run_workload() {
  infrared cloud-config --deployment-files virt --tasks launch_workload
}


if [ -z "${CA_CERT_FILE_CONTENT}" ]; then
    echo "CA_CERT_FILE_CONTENT must be set and passed to the deployment, or QDR will fail to connect."
    exit 1
fi

time if ${TEMPEST_ONLY}; then
  echo "-- Running tempest tests"
  ir_run_tempest
else
  echo "-- full cloud deployment"
  echo ">> Cloud name: ${CLOUD_NAME}"
  echo ">> Overcloud domain: ${OVERCLOUD_DOMAIN}"
  echo ">> STF enabled: ${ENABLE_STF_CONNECTORS}"
  echo ">> Gnocchi enabled: ${ENABLE_GNOCCHI_CONNECTORS}"
  echo ">> OSP version: ${OSP_VERSION}"
  echo ">> OSP build: ${OSP_BUILD}"
  echo ">> OSP topology: ${OSP_TOPOLOGY}"

  ir_run_cleanup
  if ${ENABLE_STF_CONNECTORS}; then
    stf_create_config
    enable_stf_create_config
    if [ -z "${OCP_ROUTE_IP}" ]; then
      touch outputs/extra-hosts.yaml
      truncate --size 0 outputs/extra-hosts.yaml
    else
      enable_extra_host_file_create_config
    fi
  else
    touch outputs/stf-connectors.yaml
    truncate --size 0 outputs/stf-connectors.yaml
    touch outputs/enable-stf.yaml
    truncate --size 0 outputs/enable-stf.yaml
    touch outputs/extra-hosts.yaml
    truncate --size 0 outputs/extra-hosts.yaml
  fi
  if ${ENABLE_GNOCCHI_CONNECTORS}; then
    gnocchi_create_config
  else
    touch outputs/gnocchi-connectors.yaml
    truncate --size 0 outputs/gnocchi-connectors.yaml
  fi
  ir_run_provision
  ir_create_undercloud
  ir_create_overcloud
  ir_expose_ui
  if ${RUN_WORKLOAD}; then
    ir_run_workload
  fi

  echo "-- deployment completed"
  echo ">> Cloud name: ${CLOUD_NAME}"
  echo ">> Overcloud domain: ${OVERCLOUD_DOMAIN}"
  echo ">> STF enabled: ${ENABLE_STF_CONNECTORS}"
  echo ">> Gnocchi enabled: ${ENABLE_GNOCCHI_CONNECTORS}"
  echo ">> OSP version: ${OSP_VERSION}"
  echo ">> OSP build: ${OSP_BUILD}"
  echo ">> OSP topology: ${OSP_TOPOLOGY}"
fi
