stf-run-ci
==========

Run the Service Telemetry Framework CI system. This role is intended to be
called from a playbook running locally on a preconfigured test system.
Primarily this means a running CodeReady Container system has been provided.

Requirements
------------

- CodeReady Containers
- Ansible 2.9 (tested)
- `oc` command line tool

Variables
---------

Not all variables are listed here, but these are the most common ones you might
choose to override:

| Parameter name                                         | Values                   | Default                                               | Description                                                                                                         |
| ------------------------------                         | ------------             | ---------                                             | ------------------------------------                                                                                |
| `__deploy_stf`                                         | {true,false}             | true                                                  | Whether to deploy an instance of STF                                                                                |
| `__local_build_enabled`                                | {true,false}             | true                                                  | Whether to deploy STF from local built artifacts. Also see `working_branch`, `sg_branch`, `sgo_branch`              |
| `__deploy_from_bundles_enabled`                        | {true,false}             | false                                                 | Whether to deploy STF from OLM bundles (TODO: compat with `__local_build_enabled`)                                  |
| `__service_telemetry_bundle_image_path`                | <image_path>             | <none>                                                | Image path to Service Telemetry Operator bundle                                                                     |
| `__smart_gateway_bundle_image_path`                    | <image_path>             | <none>                                                | Image path to Smart Gateway Operator bundle                                                                         |
| `prometheus_webhook_snmp_branch`                       | <git_branch>             | master                                                | Which Prometheus Webhook SNMP git branch to checkout                                                                |
| `sgo_branch`                                           | <git_branch>             | master                                                | Which Smart Gateway Operator git branch to checkout                                                                 |
| `sg_core_branch`                                       | <git_branch>             | master                                                | Which Smart Gateway Core git branch to checkout                                                                     |
| `sg_bridge_branch`                                     | <git_branch>             | master                                                | Which Smart Gateway Bridge git branch to checkout                                                                   |
| `prometheus_webhook_snmp_branch`                       | <git_branch>             | master                                                | Which Prometheus webhook snmp branch to checkout                                                                    |
| `sgo_repository`                                       | <git_repository>         | https://github.com/infrawatch/smart-gateway-operator  | Which Smart Gateway Operator git repository to clone                                                                |
| `sg_core_repository`                                   | <git_repository>         | https://github.com/infrawatch/sg-core                 | Which Smart Gateway Core git repository to clone                                                                    |
| `sg_bridge_repository`                                 | <git_repository>         | https://github.com/infrawatch/sg-bridge               | Which Smart Gateway Bridge git repository to clone                                                                  |
| `prometheus_webhook_snmp_repository`                   | <git_repository>         | https://github.com/infrawatch/prometheus-webhook-snmp | Which Prometheus webhook snmp git repository to clone                                                               |
| `loki_operator_repository`                             | <git_repository>         | https://github.com/viaq/loki-operator                 | Which Loki-operator git repository to clone                                                                         |
| `__service_telemetry_events_certificates_endpoint_cert_duration`    | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 2160h | Lifetime of the ElasticSearch endpoint certificate (minimum duration is 1h)                                         |
| `__service_telemetry_events_certificates_ca_cert_duration`          | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 70080h | Lifetime of the ElasticSearch CA certificate (minimum duration is 1h)                                              |
| `__service_telemetry_events_enabled`                   | {true,false}             | true                                                  | Whether to enable events support in ServiceTelemetry                                                                |
| `__service_telemetry_high_availability_enabled`        | {true,false}             | false                                                 | Whether to enable high availability support in ServiceTelemetry                                                     |
| `__service_telemetry_metrics_enabled`                  | {true,false}             | true                                                  | Whether to enable metrics support in ServiceTelemetry                                                               |
| `__service_telemetry_storage_ephemeral_enabled`        | {true,false}             | false                                                 | Whether to enable ephemeral storage support in ServiceTelemetry                                                     |
| `__service_telemetry_storage_persistent_storage_class` | <storage_class>          | <undefined>                                           | Set a custom storageClass to override the default provided by OpenShift platform                                    |
| `__service_telemetry_snmptraps_enabled`                | {true,false}             | true                                                  | Whether to enable snmptraps delivery via Alertmanager receiver (prometheus-webhook-snmp)                            |
| `__service_telemetry_snmptraps_community`              | <snmptrap_community>     | `public`                                              | Set the SNMP community to send traps to. Defaults to public                                                         |
| `__service_telemetry_snmptraps_target`                 | <snmptrap_target>        | `192.168.24.254`                                      | Set the SNMP target to send traps to. Defaults to 192.168.24.254                                                    |
| `__service_telemetry_snmptraps_retries`                | <snmptrap_retry_count>   | 5                                                     | Set the SNMP retry count for traps. Defaults to 5                                                                   |
| `__service_telemetry_snmptraps_port`                   | <snmptrap_port>          | 162                                                   | Set the SNMP target port for traps. Defaults to 162                                                                 |
| `__service_telemetry_snmptraps_timeout`                | <snmptrap_timeout>       | 1                                                     | Set the SNMP retry timeout (in seconds). Defaults to 1                                                              |
| `__service_telemetry_alert_oid_label`                  | <alert_label>            | oid                                                   | The alert label name to look for oid value. Default to oid.                                                         |
| `__service_telemetry_trap_oid_prefix`                  | <oid_prefix>             | 1.3.6.1.4.1.50495.15                                  | The OID prefix for trap variable bindings.                                                                          |
| `__service_telemetry_trap_default_oid`                 | <default_oid>            | 1.3.6.1.4.1.50495.15.1.2.1                            | The trap OID if none is found in the Prometheus alert labels.                                                       |
| `__service_telemetry_trap_default_severity`            | <default_severity>       | <undefined>                                           | The trap severity if none is found in the Prometheus alert labels.                                                  |
| `__service_telemetry_logs_enabled`                     | {true,false}             | false                                                 | Whether to enable logs support in ServiceTelemetry                                                                  |
| `__service_telemetry_observability_strategy`           | <observability_strategy> | `use_community`                                       | Which observability strategy to use for deployment. Default deployment is 'use_community'. Also supported are 'use_redhat', 'use_hybrid', and 'none' |
| `__service_telemetry_transports_certificates_endpoint_cert_duration`| [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 2160h | Lifetime of the QDR endpoint certificate (minimum duration is 1h)                                                   |
| `__service_telemetry_transports_certificates_ca_cert_duration`      | [ParseDuration](https://golang.org/pkg/time/#ParseDuration) | 70080h | Lifetime of the QDR CA certificate (minimum duration is 1h)                                                        |
| `__internal_registry_path`                             | <registry_path>          | image-registry.openshift-image-registry.svc:5000      | Path to internal registry for image path                                                                            |
| `__deploy_loki_enabled`                                | {true,false}             | false                                                 | Whether to deploy loki-operator and other systems for logging development purposes                                  |
| `__golang_image_path`                                  | <image_path>             | quay.io/infrawatch/golang:1.16                        | Golang image path for building the loki-operator image                                                              |
| `__loki_image_path`                                    | <image_path>             | quay.io/infrawatch/loki:2.2.1                         | Loki image path for Loki microservices                                                                              |



Example Playbook
----------------

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

Usage
-----

You can deploy Service Telemetry Framework using this role in a few
configuration methods:

* local build artifacts from Git repository cloned locally
* standard deployment using Subscription and OLM
* supporting components but no instance of Service Telemetry Operator

You can deploy using the sample `run-ci.yaml` from the _Example Playbook_
section:

```
ansible-playbook run-ci.yaml
```

If you want to do a standard deployment (existing remote artifacts) you can use
the following command:

```
ansible-playbook --extra-vars __local_build_enabled=false run-ci.yaml
```

You can deploy directly from pre-built bundles like this:
```
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
not required, add `--skip-tags bundle_registry_tls_ca`. If no login is required
to your bundle image registry, add `--skip-tags bundle_registry_auth`

License
-------

Apache v2.0

Author Information
------------------

Leif Madsen
