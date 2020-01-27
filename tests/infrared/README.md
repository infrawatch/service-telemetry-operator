# Integration tests

Use Infrared (and optionally minishift) to test a simple OSP cluster connected
to an SAF instance all on one (large) baremetal machine.

## Usage

1. Have `ir --version` working
1. Have `oc` tools working and pointed at a deploy SAF namespace
1. Set VIRTHOST and have key based SSH access to root@$VIRTHOST
1. (optional - not yet fully working) Run `minishift-saf.sh` to install OCP + SAF on $VIRTHOST
    * Ensure the smoketest is passing before proceeding
1. (optional) Set AMQP_HOST to point to your SAF
    * Default is taken from the route if `oc` is pointing to your SAF namespace
1. Run `infrared-openstack.sh` to install OSP on $VIRTHOST
(Cry when it fails; try to pick up where it left off)

## Verification

Once the deployment is complete, you can check prometheus for data, like so:

```shells
$ PROM_HOST=$(oc get route prometheus -o jsonpath='{.spec.host}')
$ curl "http://${PROM_HOST}/api/v1/query?query=sa_collectd_uptime\[10s\]"
{"status":"success","data":{"resultType":"matrix","result":[{"metric":{"__name__":"sa_collectd_uptime","endpoint":"prom-http","exported_instance":"compute-0.localdomain","service":"white-smartgateway","type":"base","uptime":"base"},"values":[[1566500715.207,"88719"],[1566500716.214,"88720"],[1566500717.207,"88721"],[1566500718.207,"88722"],[1566500720.207,"88724"],[1566500721.207,"88725"],[1566500722.207,"88726"],[1566500723.207,"88727"]]},{"metric":{"__name__":"sa_collectd_uptime","endpoint":"prom-http","exported_instance":"controller-0.localdomain","service":"white-smartgateway","type":"base","uptime":"base"},"values":[[1566500715.207,"88700"],[1566500717.207,"88701"],[1566500718.207,"88702"],[1566500719.209,"88703"],[1566500721.207,"88704"],[1566500723.207,"88705"]]}]}}
```

You should be seeing samples for both compute-0 and controller-0

## Versions

Tested with the following versions:

* infrared
  * 2.0.1.dev3506 (ansible-2.7.12, python-2.7.5)
* oc
  * v3.11.0+0cbc58b
* "Virthost"
  * RHEL 7.6

## TODO
* Stamp out the few remaining IP addresses and RH internal defaults
* Get the minishift on VIRTHOST scenario working
* Automated verification script
