# Integration tests

Use Infrared (and optionally minishift) to test a simple OSP cluster connected
to an STF instance all on one (large) baremetal machine.

## Usage

1. Have `ir --version` working with at least these plugins: 
    * virsh tripleo-undercloud tripleo-overcloud cloud-config tempest
1. Set VIRTHOST and have key based SSH access to root@$VIRTHOST
1. Set AMQP_HOST and AMQP_PORT
1. (OSP 13/17) `export CA_CERT_FILE_CONTENT=$(oc get secret/default-interconnect-selfsigned -o jsonpath='{.data.ca\.crt}' | base64 -d)`
1. Run `infrared-openstack.sh` to install OSP on $VIRTHOST

## Verification

Once the deployment is complete, you can check prometheus for data, like so:

```shells
$ PROM_HOST=$(oc get route default-prometheus-proxy -o jsonpath='{.spec.host}')
$ curl "http://${PROM_HOST}/api/v1/query?query=collectd_uptime\[10s\]"
{"status":"success","data":{"resultType":"matrix","result":[{"metric":{"__name__":"collectd_uptime","endpoint":"prom-http","host":"compute-0.localdomain","service":"white-smartgateway","type":"base","uptime":"base"},"values":[[1566500715.207,"88719"],[1566500716.214,"88720"],[1566500717.207,"88721"],[1566500718.207,"88722"],[1566500720.207,"88724"],[1566500721.207,"88725"],[1566500722.207,"88726"],[1566500723.207,"88727"]]},{"metric":{"__name__":"collectd_uptime","endpoint":"prom-http","host":"controller-0.localdomain","service":"white-smartgateway","type":"base","uptime":"base"},"values":[[1566500715.207,"88700"],[1566500717.207,"88701"],[1566500718.207,"88702"],[1566500719.209,"88703"],[1566500721.207,"88704"],[1566500723.207,"88705"]]}]}}
```

You should be seeing samples for both compute-0 and controller-0

## Versions

Tested with the following versions:

* infrared
  * 2.0.1.dev3952 (ansible-2.7.16, python-2.7.5)
* "Virthost"
  * RHEL 7.6

## TODO
* Stamp out the few remaining IP addresses and RH internal defaults
* Get the crc on VIRTHOST scenario working
* Automated verification script
