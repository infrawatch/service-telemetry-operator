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

| Parameter name                                         | Values          | Default                                          | Description                                                                                           |
| ------------------------------                         | ------------    | ---------                                        | ------------------------------------                                                                  |
| `__deploy_stf`                                         | {true,false}    | true                                             | Whether to deploy an instance of STF                                                                  |
| `__local_build_enabled`                                | {true,false}    | true                                             | Whether to deploySTF from local built artifacts. Also see `working_branch`, `sg_branch`, `sgo_branch` |
| `__deploy_from_bundles_enabled`                        | {true,false}             | false                                                |  Whether to deploy STF from OLM bundles (TODO: compat with __local_build_enabled) |
| `__service_telemetry_bundle_image_path`                | <image_path>             | <none>                                                | Image path to Service Telemetry Operator bundle |
| `__smart_gateway_bundle_image_path`                    | <image_path>             | <none>                                                | Image path to Smart Gateway Operator bundle |
| `prometheus_webhook_snmp_branch`                       | <git_branch>    | master                                           | Which Prometheus Webhook SNMP git branch to checkout                                                  |
| `sgo_branch`                                           | <git_branch>    | master                                           | Which Smart Gateway Operator git branch to checkout                                                   |
| `sg_branch`                                            | <git_branch>    | master                                           | Which Smart Gateway git branch to checkout                                                            |
| `sg_core_branch`                                       | <git_branch>    | master                                           | Which Smart Gateway Core git branch to checkout                                                       |
| `sg_bridge_branch`                                     | <git_branch>    | master                                           | Which Smart Gateway Bridge git branch to checkout                                                     |
| `__service_telemetry_events_enabled`                   | {true,false}    | true                                             | Whether to enable events support in ServiceTelemetry                                                  |
| `__service_telemetry_high_availability_enabled`        | {true,false}    | false                                            | Whether to enable high availability support in ServiceTelemetry                                       |
| `__service_telemetry_metrics_enabled`                  | {true,false}    | true                                             | Whether to enable metrics support in ServiceTelemetry                                                 |
| `__service_telemetry_storage_ephemeral_enabled`        | {true,false}    | false                                            | Whether to enable ephemeral storage support in ServiceTelemetry                                       |
| `__service_telemetry_snmptraps_enabled`                | {true,false}    | true                                             | Whether to enable snmptraps delivery via Alertmanager receiver (prometheus-webhook-snmp)              |
| `__service_telemetry_storage_persistent_storage_class` | <storage_class> | <undefined>                                      | Set a custom storageClass to override the default provided by OpenShift platform                      |
| `__internal_registry_path`                             | <registry_path> | image-registry.openshift-image-registry.svc:5000 | Path to internal registry for image path                                                              |

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
