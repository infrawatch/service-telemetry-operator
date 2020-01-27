# SAF Testing notes

Here are some artifacts to assist with testing the SAF after it is deployed.

Currently this is just a "smoke test" that runs internal to the OCP cluster. It
delivers collectd data to the SAF amqp node and verifies that it can be seen in
prometheus. This is intended to be usable for developers and TravisCI to
validate our builds before merging changes to this repo.

## Usage

1. Have `oc` pointing at your sa-telemetry project and run `./smoketest.sh`
1. Run `oc get jobs` and check the result of the saf-smoketest job
1. (If necessary) Check the logs of the saf-smoketest pod

### Example

```
$ ./smoketest.sh
configmap "saf-smoketest-collectd-config" deleted
configmap "saf-smoketest-entrypoint-script" deleted
job.batch "saf-smoketest" deleted
configmap/saf-smoketest-collectd-config created
configmap/saf-smoketest-entrypoint-script created
job.batch/saf-smoketest created

$ oc get jobs
NAME            DESIRED   SUCCESSFUL   AGE
saf-smoketest   1         1            18s

$ oc get pods -l name=saf-smoketest
NAME                  READY     STATUS      RESTARTS   AGE
saf-smoketest-md967   0/1       Completed   0          18s

$ oc logs saf-smoketest-md967
Sleeping for 3 seconds waiting for collectd to enter read-loop
plugin_load: plugin "cpu" successfully loaded.
plugin_load: plugin "amqp1" successfully loaded.
Initialization complete, entering read-loop.
Initialization complete, entering read-loop.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   328  100   262  100    66  16926   4263 --:--:-- --:--:-- --:--:-- 17466
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"sa_collectd_cpu_total","cpu":"0","endpoint":"metrics","exported_instance":"saf-smoketest-md967","service":"white-smartgateway","type":"user"},"value":[1562363042.123,"518777"]}]}}
```

## Improvements

These are some things that would make this better:

* Would like to actually test via the AMQP+TLS interface as the system boundary
  instead of directly to the internal AMQP broker
  * Option to do internal vs. external
