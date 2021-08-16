# STF Performance Test

## Introduction

The performance test provides an automated environment in which to to run stress
tests on STF. Collectd-tg or telemetry-bench are used to simulate extensive
metrics data to pump through STF. Results of testing can be analyzed in a
grafana dashboard.

Two additional pods are deployed by the performance test: one that hosts a
grafana instance and one that executes the testing logic.

![A Performance Test Dashboard](../images/dashboard.png)

## Environment

* openshift v4.2.7

## Setup

STF must already be deployed including the default ServiceTelemetry example CR.
A quick way to do this is using the `quickstart.sh` script in
`service-telemetry-operator/deploy/` directory to run STF.

 Here is an example of how to do that in crc:

 ```shell
crc start
eval $(crc oc-env)
cd service-telemetry-operator/deploy/; ./quickstart.sh
```

## Deploying Grafana

Ensure that all of the STF pods are already marked running with `oc get pods`.
Next, launch the grafana instance for test results gathering. This only needs
to be done once:

```shell
cd service-telemetry-operator/tests/performance-test/grafana
./grafana-launcher.sh
```

The grafana launcher script will output a URL that can be used to log into the
dashboard. This Grafana instance has all authentication disabled - if, in the
future, the performance test should report to an authenticated grafana instance,
the test scripts must be modified.

## Launching the test

Once the Grafana instance is running, launch the performance test OpenShift job:

```shell
./performance-test.sh
```

Monitor the performance test status by watching the job with
`oc get job -l app=stf-performance-test -w`. Logs can be viewed with
`oc logs stf-perftest-<NUM>-runner-<ID> -f`
