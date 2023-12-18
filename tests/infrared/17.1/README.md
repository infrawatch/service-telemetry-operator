# Deployments

## Basic deployment

A basic deployment can be deployed and connected to an existing STF deployment automatically after logging into the OpenShift cluster hosting STF from the host system.

### Prequisites

* Logged into the host system where you'll deploy the virtualized OpenStack infrastructure.
* Installed infrared and cloned the infrawatch/service-telemetry-operator repository.
* DNS resolution (or `/etc/hosts` entry) of the OpenShift cluster API endpoint.
* Downloaded the `oc` binary, made it executable, and placed in $PATH.
* Logged into the OpenShift hosting STF and changed to the `service-telemetry` project from the host system.

### Procedure

* Deploy the overcloud using the infrawatch-openstack.sh script:
  ```bash
  OCP_ROUTE_IP="10.0.111.41" \
  CA_CERT_FILE_CONTENT="$(oc get secret/default-interconnect-selfsigned -o jsonpath='{.data.ca\.crt}' | base64 -d)" \
  AMQP_HOST="$(oc get route default-interconnect-5671 -ojsonpath='{.spec.host}')" \
  AMQP_PASS="$(oc get secret default-interconnect-users -o json | jq -r .data.guest | base64 -d)" \
  ENABLE_STF_CONNECTORS=true \
  ENABLE_GNOCCHI_CONNECTORS=false \
  CONTROLLER_MEMORY="24000" \
  COMPUTE_CPU="6" \
  COMPUTE_MEMORY="24000" \
  LIBVIRT_DISKPOOL="/home/libvirt/images" \
  ./infrared-openstack.sh
  ```

## Running a test workload

You can run a test workload on the deployed overcloud by logging into the undercloud and completing some additional setup to allow for virtual machine workloads to run.

### Procedure

* Login to the undercloud from the host system:
  ```bash
  ir ssh undercloud-0
  ```
* Complete the deployment of a private network, router, and other aspects to allow the virtual machine to be deployed:
  ```bash
  source overcloudrc
  export PRIVATE_NETWORK_CIDR=192.168.100.0/24
  openstack flavor create --ram 512 --disk 1 --vcpu 1 --public tiny
  curl -L -O https://download.cirros-cloud.net/0.5.0/cirros-0.5.0-x86_64-disk.img
  openstack image create cirros --container-format bare --disk-format qcow2 --public --file cirros-0.5.0-x86_64-disk.img
  openstack keypair create --public-key ~/.ssh/id_rsa.pub default
  openstack security group create basic
  openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
  openstack security group rule create --protocol icmp basic
  openstack security group rule create --protocol udp --dst-port 53:53 basic
  openstack network create --internal private
  openstack subnet create private-net \
    --subnet-range $PRIVATE_NETWORK_CIDR \
    --network private
  openstack router create vrouter
  openstack router set vrouter --external-gateway public
  openstack router add subnet vrouter private-net
  openstack server create --flavor tiny --image cirros --key-name default --security-group basic --network private myserver
  until [ "$(openstack server list --name myserver --column Status --format value)" = "ACTIVE" ]; do echo "Waiting for server to be ACTIVE..."; sleep 10; done
  openstack server add floating ip myserver $(openstack floating ip create public --format json | jq .floating_ip_address | tr -d '"')
  openstack server list
  ```
