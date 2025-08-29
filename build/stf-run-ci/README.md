# stf-run-ci

Run the Service Telemetry Framework CI system. This role is intended to be
called from a playbook running locally on a preconfigured test system.
Primarily this means a running CodeReady Container system has been provided.

## Requirements

- CodeReady Containers
- Ansible 2.9 (tested)
- `oc` command line tool

## Variables

Not all variables are listed here, but these are the most common ones you might
choose to override:

| Parameter name                                                       | Values                                                      | Default                                                                       | Description                                                                                                                                                                                                             |
| ------------------------------                                       | ------------                                                | ---------                                                                     | ------------------------------------                                                                                                                                                                                    |
| `__deploy_stf`                                                       | {true,false}                                                | true                                                                          | Whether to deploy an instance of STF                                                                                                                                                                                    |
| `__local_build_enabled`                                              | {true,false}                                                | true                                                                          | Whether to deploy STF from local built artifacts. Also see `working_branch`, `sg_branch`, `sgo_branch`                                                                                                                  |
| `__deploy_from_bundles_enabled`                                      | {true,false}                                                | false                                                                         | Whether to deploy STF from OLM bundles (TODO: compat with `__local_build_enabled`)                                                                                                                                      |
| `__deploy_from_index_enabled`                                        | {true,false}                                                | false                                                                         | Whether to deploy STF from locally built bundles/OLM bundles and index image.                                                                                                                                                       |
| `__deploy_from_catalog`                                              | {true,false}                                                | false                                                                         | Whether to deploy STF from a pre-built index image.                                                                                                                                                                    |
| `__disconnected_deploy`                                              | {true,false}                                                | false                                                                         | Whether to deploy on a disconnected cluster                                                                                                                                                                               |
| `__service_telemetry_bundle_image_path`                              | <image_path>                                                | `quay.io/infrawatch-operators/service-telemetry-operator-bundle:nightly-head` | Image path to Service Telemetry Operator bundle                                                                                                                                                                         |
| `__smart_gateway_bundle_image_path`                                  | <image_path>                                                | `quay.io/infrawatch-operators/smart-gateway-operator-bundle:nightly-head`     | Image path to Smart Gateway Operator bundle                                                                                                                                                                             |
| `__stf_catalog_index_image_path`                                     | <image_path>                                                | `quay.io/infrawatch-operators/infrawatch-catalog:nightly`                     | Index image path to STF catalog                                                                                                                                                                                              |
| `setup_bundle_registry_tls_ca`                                       | {true,false}                                                | true                                                                          | Whether to setup or not a TLS CA cert for the bundle registry access                                                                                                                                                    |
| `setup_bundle_registry_auth`                                         | {true,false}                                                | true                                                                          | Whether to setup or not the auth for the bundle registry access                                                                                                                                                         |
| `prometheus_webhook_snmp_branch`                                     | <git_branch>                                                | master                                                                        | Which Prometheus Webhook SNMP git branch to checkout                                                                                                                                                                    |
| `sgo_branch`                                                         | <git_branch>                                                | master                                                                        | Which Smart Gateway Operator git branch to checkout                                                                                                                                                                     |
| `sg_core_branch`                                                     | <git_branch>                                                | master                                                                        | Which Smart Gateway Core git branch to checkout                                                                                                                                                                         |
| `sg_bridge_branch`                                                   | <git_branch>                                                | master                                                                        | Which Smart Gateway Bridge git branch to checkout                                                                                                                                                                       |
| `prometheus_webhook_snmp_branch`                                     | <git_branch>                                                | master                                                                        | Which Prometheus webhook snmp branch to checkout                                                                                                                                                                        |
| `sgo_repository`                                                     | <git_repository>                                            | https://github.com/infrawatch/smart-gateway-operator                          | Which Smart Gateway Operator git repository to clone                                                                                                                                                                    |
| `sg_core_repository`                                                 | <git_repository>                                            | https://github.com/infrawatch/sg-core                                         | Which Smart Gateway Core git repository to clone                                                                                                                                                                        |
| `sg_bridge_repository`                                               | <git_repository>                                            | https://github.com/infrawatch/sg-bridge                                       | Which Smart Gateway Bridge git repository to clone                                                                                                                                                                      |
| `prometheus_webhook_snmp_repository`                                 | <git_repository>                                            | https://github.com/infrawatch/prometheus-webhook-snmp                         | Which Prometheus webhook snmp git repository to clone                                                                                                                                                                   |
| `clone_repos`                                                        | {true, false}                                               | true                                                                          | Whether to clone the repos. If false, the repos will not be cloned, and the user will need to specify a value for `sto_dir`. The location of the other repos may need to be specified as well. (see relevant sections). |
| `sto_dir`                                                            | <directory_path>                                            | `{{ playbook_dir }}/..`                                                       | The location of the service-telemetry-operator directory (needed to set the other repo paths)                                                                                                                           |
| `sgo_dir`                                                            | <directory_path>                                            | `{{ sto_dir }}/build/working/smart-gateway-operator`                          | The directory to clone smart-gateway-operator into (when clone_repos == true) or the location of the the repo (when clone_repos == false)                                                                               |
| `sg_core_dir`                                                        | <directory_path>                                            | `{{ sto_dir }}/build/working/sg-core`                                         | See description of sgo_dir                                                                                                                                                                                              |
| `sg_bridge_dir`                                                      | <directory_path>                                            | `{{ sto_dir }}/build/working/sg-bridge`                                       | See description of sgo_dir                                                                                                                                                                                              |
| `prometheus_webhook_snmp_dir`                                        | <directory_path>                                            | `{{ sto_dir }}/build/working/prometheus-webhook-snmp`                         | See description of sgo_dir                                                                                                                                                                                              |
| `__service_telemetry_events_certificates_endpoint_cert_duration`     | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 70080h                                                                        | Lifetime of the ElasticSearch endpoint certificate (minimum duration is 1h)                                                                                                                                             |
| `__service_telemetry_events_certificates_ca_cert_duration`           | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 70080h                                                                        | Lifetime of the ElasticSearch CA certificate (minimum duration is 1h)                                                                                                                                                   |
| `__service_telemetry_events_enabled`                                 | {true,false}                                                | true                                                                          | Whether to enable events support in ServiceTelemetry                                                                                                                                                                    |
| `__service_telemetry_high_availability_enabled`                      | {true,false}                                                | false                                                                         | Whether to enable high availability support in ServiceTelemetry                                                                                                                                                         |
| `__service_telemetry_metrics_enabled`                                | {true,false}                                                | true                                                                          | Whether to enable metrics support in ServiceTelemetry                                                                                                                                                                   |
| `__service_telemetry_storage_ephemeral_enabled`                      | {true,false}                                                | false                                                                         | Whether to enable ephemeral storage support in ServiceTelemetry                                                                                                                                                         |
| `__service_telemetry_storage_persistent_storage_class`               | <storage_class>                                             | <undefined>                                                                   | Set a custom storageClass to override the default provided by OpenShift platform                                                                                                                                        |
| `__service_telemetry_snmptraps_enabled`                              | {true,false}                                                | true                                                                          | Whether to enable snmptraps delivery via Alertmanager receiver (prometheus-webhook-snmp)                                                                                                                                |
| `__service_telemetry_snmptraps_community`                            | <snmptrap_community>                                        | `public`                                                                      | Set the SNMP community to send traps to. Defaults to public                                                                                                                                                             |
| `__service_telemetry_snmptraps_target`                               | <snmptrap_target>                                           | `192.168.24.254`                                                              | Set the SNMP target to send traps to. Defaults to 192.168.24.254                                                                                                                                                        |
| `__service_telemetry_snmptraps_retries`                              | <snmptrap_retry_count>                                      | 5                                                                             | Set the SNMP retry count for traps. Defaults to 5                                                                                                                                                                       |
| `__service_telemetry_snmptraps_port`                                 | <snmptrap_port>                                             | 162                                                                           | Set the SNMP target port for traps. Defaults to 162                                                                                                                                                                     |
| `__service_telemetry_snmptraps_timeout`                              | <snmptrap_timeout>                                          | 1                                                                             | Set the SNMP retry timeout (in seconds). Defaults to 1                                                                                                                                                                  |
| `__service_telemetry_alert_oid_label`                                | <alert_label>                                               | oid                                                                           | The alert label name to look for oid value. Default to oid.                                                                                                                                                             |
| `__service_telemetry_trap_oid_prefix`                                | <oid_prefix>                                                | 1.3.6.1.4.1.50495.15                                                          | The OID prefix for trap variable bindings.                                                                                                                                                                              |
| `__service_telemetry_trap_default_oid`                               | <default_oid>                                               | 1.3.6.1.4.1.50495.15.1.2.1                                                    | The trap OID if none is found in the Prometheus alert labels.                                                                                                                                                           |
| `__service_telemetry_trap_default_severity`                          | <default_severity>                                          | <undefined>                                                                   | The trap severity if none is found in the Prometheus alert labels.                                                                                                                                                      |
| `__service_telemetry_observability_strategy`                         | <observability_strategy>                                    | `use_redhat`                                                                  | Which observability strategy to use for deployment. Default is 'use_redhat'. Also supported are 'use_hybrid', 'use_community', and 'none'                                                                               |
| `__service_telemetry_transports_qdr_auth`                            | {'none', 'basic'}                                           | `none`                                                                        | Which auth method to use for QDR. Can be 'none' or 'basic'. Note: 'basic' is not yet supported in smoketests.                                                                                                           |
| `__service_telemetry_transports_certificates_endpoint_cert_duration` | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 70080h                                                                        | Lifetime of the QDR endpoint certificate (minimum duration is 1h)                                                                                                                                                       |
| `__service_telemetry_transports_certificates_ca_cert_duration`       | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 70080h                                                                        | Lifetime of the QDR CA certificate (minimum duration is 1h)                                                                                                                                                             |
| `__internal_registry_path`                                           | <registry_path>                                             | image-registry.openshift-image-registry.svc:5000                              | Path to internal registry for image path                                                                                                                                                                                |


# Example Playbook

```yaml
---
# run STF CI setup in CRC (already provisioned)
- hosts: localhost
  connection: local
  tasks:
  - name: Run the STF CI system
    import_role:
        name: stf-run-ci
```

# Usage

You can deploy Service Telemetry Framework using this role in a few
configuration methods:

* local build artifacts from Git repository cloned locally (local build)
* local build artifacts, local bundle artifacts, and Subscription via OLM using locally built index image (local build + deploy from index)
* externally build bundle artifacts and Subscription via OLM using locally built index image (deploy from bundles + deploy from index)
* standard deployment using Subscription and OLM (deploy from bundles)
* supporting components but no instance of Service Telemetry Operator

## Basic deployment

You can deploy using the sample `run-ci.yaml` from the _Example Playbook_
section:

```sh
ansible-playbook run-ci.yaml
```

## Standard deloyment with existing artifacts

If you want to do a standard deployment (existing remote artifacts) you can use
the following command:

```sh
ansible-playbook --extra-vars __local_build_enabled=false run-ci.yaml
```

## Deployment with pre-build bundles

You can deploy directly from pre-built bundles like this:

```sh
ansible-playbook -e __local_build_enabled=false -e __deploy_from_bundles_enabled=true \
  -e __service_telemetry_bundle_image_path=<registry>/<namespace>/stf-service-telemetry-operator-bundle:<tag> \
  -e __smart_gateway_bundle_image_path=<registry>/<namespace>/stf-smart-gateway-operator-bundle:<tag> \
  -e pull_secret_registry=<registry> \
  -e pull_secret_user=<username> \
  -e pull_secret_pass=<password>
  run-ci.yaml
```

NOTE: When deploying from bundles, you must have a _CA.pem_ for
the registry already in place in the build directory, if required. If this is
not required, set `setup_bundle_registry_tls_ca` to `false`. If no login is required
to your bundle image registry, set `setup_bundle_registry_auth` to `false`.
By default, those configuration options are set to `true`.

## Deployment from local artifacts, bundles, and index

You can perform a deployment using OLM and a Subscription from locally built artifacts, bundles, and index image like this:

```sh
ansible-playbook -e __local_build_enabled=true -e __deploy_from_index_enabled=true run-ci.yaml
```

## Deployment with pre-built bundles and locally created index image

Instead of relying on the operator-sdk to deploy from selected bundles using the "operator-sdk run bundle" utility,
you can perform a deployment using OLM and a Subscription to a locally created index image like this:

```sh
ansible-playbook -e __local_build_enabled=false -e __deploy_from_bundles_enabled=true \
  -e __deploy_from_index_enabled=true \
  -e __service_telemetry_bundle_image_path=<registry>/<namespace>/stf-service-telemetry-operator-bundle:<tag> \
  -e __smart_gateway_bundle_image_path=<registry>/<namespace>/stf-smart-gateway-operator-bundle:<tag> \
  -e pull_secret_registry=<registry> \
  -e pull_secret_user=<username> \
  -e pull_secret_pass=<password>
  run-ci.yaml
```

Since you will fetch the selected images from a bundle registry, it is required that you have all the required
access credentials for the desired registry correctly configured. Check the "Deployment with pre-build bundles"
docs above to get more information about this.

## Deployment with pre-built index image

Is it also possible to pass the path for a pre-build index image to create a CatalogSource and deploy STF from it.
This can be done as follows:

```sh
ansible-playbook -e __local_build_enabled=false -e __deploy_from_catalog=true \
  -e __stf_catalog_index_image_path=<registry>/<namespace>/infrawatch-catalog:<tag> \
  -e pull_secret_registry=<registry> \
  -e pull_secret_user=<username> \
  -e pull_secret_pass=<password>
  run-ci.yaml
```

# License

Apache v2.0

# Author Information

Red Hat (CloudOps DFG)
