# Deployments

## Basic deployment

```bash
CA_CERT_FILE_CONTENT="$(oc get secret/default-interconnect-selfsigned -o jsonpath='{.data.ca\.crt}' | base64 -d)" \
OCP_ROUTE_IP="10.0.100.50" \
AMQP_HOST="default-interconnect-5671-service-telemetry.apps.stf15.localhost" \
ENABLE_STF_CONNECTORS=true \
ENABLE_GNOCCHI_CONNECTORS=false \
CONTROLLER_MEMORY="24000" \
COMPUTE_CPU="6" \
COMPUTE_MEMORY="24000" \
LIBVIRT_DISKPOOL="/home/libvirt/images" \
./infrared-openstack.sh
```
