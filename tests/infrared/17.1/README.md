# Deployments

## Basic deployment

```bash
OCP_ROUTE_IP="10.0.100.50" \
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
