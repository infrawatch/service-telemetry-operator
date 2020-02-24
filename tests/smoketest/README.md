# STF Testing notes

Here are some artifacts to assist with testing the STF after it is deployed.

Currently this is just a "smoke test" that runs internal to the OCP cluster. It
delivers collectd data to the STF amqp node and verifies that it can be seen in
prometheus. This is intended to be usable for developers and TravisCI to
validate our builds before merging changes to this repo.

## Usage

1. Have `oc` pointing at your service-telemetry project and run `./smoketest.sh`
1. Run `oc get jobs` and check the result of the stf-smoketest job
1. (If necessary) Check the logs of the stf-smoketest pod

### Example

```
$ ./smoketest.sh
configmap "stf-smoketest-collectd-config" deleted
configmap "stf-smoketest-entrypoint-script" deleted
job.batch "stf-smoketest" deleted
configmap/stf-smoketest-collectd-config created
configmap/stf-smoketest-entrypoint-script created
job.batch/stf-smoketest created

$ oc get jobs
NAME            DESIRED   SUCCESSFUL   AGE
stf-smoketest   1         1            18s

$ oc get pods -l name=stf-smoketest
NAME                  READY     STATUS      RESTARTS   AGE
stf-smoketest-md967   0/1       Completed   0          18s

$ oc logs stf-smoketest-md967
Sleeping for 3 seconds waiting for collectd to enter read-loop
plugin_load: plugin "cpu" successfully loaded.
plugin_load: plugin "amqp1" successfully loaded.
Initialization complete, entering read-loop.
Initialization complete, entering read-loop.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   328  100   262  100    66  16926   4263 --:--:-- --:--:-- --:--:-- 17466
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"collectd_cpu_total","cpu":"0","endpoint":"metrics","exported_instance":"stf-smoketest-md967","service":"white-smartgateway","type":"user"},"value":[1562363042.123,"518777"]}]}}
```

## Improvements

These are some things that would make this better:

* Would like to actually test via the AMQP+TLS interface as the system boundary
  instead of directly to the internal AMQP broker
  * Option to do internal vs. external
