# service-telemetry-operator

Umbrella Operator to instantiate all required components for Service Telemetry
Framework.

## Getting Started

You'll need to do the following steps in order to load the prerequisites for
deploying to an OpenShift 4.x environment:

* import catalog containing Service Telemetry and Smart Gateway Operators via
  OperatorSource file
* install the AMQ Certificate Manager Operator before installing Service
  Telemetry Operator
* install the Service Telemetry Operator

## Starting up Service Telemetry

In the OperatorHub, select "Service Telemetry Operator" and install it. You can
use the defaults.

Once the Service Telemetry Operator is available in the _Installed Operators_
page, select _Service Telemetry Operator_ and select _Create instance_ within
the _SAF Cluster_ box under _Provided APIs_. Then press _Create_.

## Overriding Default Manifests

The following variables can be passed to a new instance of SAF Cluster (kind:
ServiceTelemetry) via the YAML configuration to override the default manifests
loaded for you.

* prometheus_manifest
* alertmanager_config_manifest
* alertmanager_manifest
* elasticsearch_secret_manifest
* interconnect_manifest
* elasticsearch_manifest
* smartgateway_metrics_manifest
* smartgateway_events_manifest
* servicemonitor_manifest

## Development

The quickest way to start up Service Telemetry Framework for development is to
run the `quickstart.sh` script located in the `deploy/` directory after starting
up a [Code Ready Containers](https://github.com/code-ready/crc) environment.

To deploy a local build of the Service Telemetry Operator itself, start by
running `build/build_ci.sh`. Once that's done, you can test new builds of the
core operator code like this:

```shell
./build/build.sh &&\
./build/push_container2ocp.sh &&\
oc delete po -l name=service-telemetry-operator
```

## Tech Preview

See the [official
documentation](https://redhat-service-assurance.github.io/stf-documentation)
for more information about installing for production-style use cases on OCP3.

Please use [the legacy stf-ocp3 branch](https://github.com/redhat-service-assurance/telemetry-framework/tree/stf-ocp3) for all such installations.

## CI

### Travis

* Runs OLM and Ansible linting

### Hybrid DIY CI

* We run an internal CI server that smoketests builds and publishes the results
* WIP - Not fully implemented yet
