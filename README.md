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
the _STF Cluster_ box under _Provided APIs_. Then press _Create_.

## Overriding Default Manifests

The following variables can be passed to a new instance of STF Cluster (`kind:
ServiceTelemetry`) via the YAML configuration to override the default manifests
loaded for you.

* prometheusManifest
* alertmanagerConfigManifest
* alertmanagerManifest
* elasticsearchSecretManifest
* interconnectManifest
* elasticsearchManifest
* grafanaManifest
* smartgatewayCollectdMetricsManifest
* smartgatewayCollectdEventsManifest
* smartgatewayCeilometerEventsManifest
* servicemonitorManifest

## Development

The quickest way to start up Service Telemetry Framework for development is to
run the `quickstart.sh` script located in the `deploy/` directory after starting
up a [CodeReady Containers](https://github.com/code-ready/crc) environment.

To deploy a local build of the Service Telemetry Operator itself, start by
running `ansible-playbook build/run-ci.yaml`. If you have code to coordinate
across the supporting InfraWatch repositories, you can pass the
`working_branch` paramater to the `--extra-vars` flag like so:

```shell
ansible-playbook \
    --extra-vars working_branch="username-new_feature" \
    build/run-ci.yaml
```

Additional flags for overriding various branch and path names is documented in
`build/stf-run-ci/README.md`.

## CI

### Travis

* Runs OLM and Ansible linting

### Hybrid DIY CI

* We run an internal CI server that smoketests builds and publishes the results
* WIP - Not fully implemented yet
