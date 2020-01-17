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
