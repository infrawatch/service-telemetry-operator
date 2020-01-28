# service-assurance-operator

Umbrella Operator to instantiate all required components for Service Assurance
Framework.

## Getting Started

You'll need to do the following steps in order to load the prerequisites for
deploying to an OpenShift 4.x environment:

* import catalog containing Service Assurance and Smart Gateway Operators via
  OperatorSource file
* install the AMQ Certificate Manager Operator before installing Service
  Assurance Operator
* install the Service Assurance Operator

## Starting up Service Assurance

In the OperatorHub, select "Service Assurance Operator" and install it. You can
use the defaults.

Once the Service Assurance Operator is available in the _Installed Operators_
page, select _Service Assurance Operator_ and select _Create instance_ within
the _SAF Cluster_ box under _Provided APIs_. Then press _Create_.

## Overriding Default Manifests

The following variables can be passed to a new instance of SAF Cluster (kind:
ServiceAssurance) via the YAML configuration to override the default manifests
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

The quickest way to start up Service Assurance Framework for development is to
run the `quickstart.sh` script located in the `deploy/` directory after starting
up a [Code Ready Containers](https://github.com/code-ready/crc) environment.

To deploy a local build of the Service Assurance Operator itself, follow the
process shown in `build/build_ci.sh`.

## Tech Preview

See the [official
documentation](https://redhat-service-assurance.github.io/saf-documentation)
for more information about installing for production-style use cases on OCP3.

Please use [the legacy saf-ocp3 branch](https://github.com/redhat-service-assurance/telemetry-framework/tree/saf-ocp3) for all such installations.

## CI

### Travis

* Runs OLM and Ansible linting

### Hybrid DYI CI

* We run an internal CI server that smoketests builds and publishes the results
* WIP - Not fully implemented yet