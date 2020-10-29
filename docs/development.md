# CodeReady Containers

Our target platform is OKD 4.x for upstream deployments, and Red Hat OpenShift
Container Platform for downstream deployments. Until OKD 4.x is made available,
our development environment remains CodeReady Containers, which is a minikube
style installation for OpenShift 4.x.

You can download CodeReady Containers (with the required Red Hat Developer
access) from
https://developers.redhat.com/products/codeready-containers/overview

> **NOTE**
>
> In the future we intend to update these instructions should testing be done
> on alternative platforms such as minikube or availability of a
> minishift-style development tool.

## Set up CRC and buildah

Setup CRC and then login with the `kubeadmin` user.

```
$ crc setup
$ crc start --memory=32768
$ crc console --credentials
```

Install `buildah` via `dnf`.

```
sudo dnf install buildah -y
```

Enable the local registry.

```
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
```

## Login to CRC registry

```
REGISTRY=$(oc registry info)
TOKEN=$(oc whoami -t)
INTERNAL_REGISTRY=$(oc registry info --internal=true)
buildah login --tls-verify=false -u openshift -p "${TOKEN}" "${REGISTRY}"
```

### Create working project (namespace)

Create a working project for the application.

```
oc new-project service-telemetry
```

## Build the operator

```
buildah bud -f build/Dockerfile -t "${REGISTRY}/service-telemetry/service-telemetry-operator:latest" .
buildah push --tls-verify=false "${REGISTRY}/service-telemetry/service-telemetry-operator:latest"
```

## Dependency resolution

<TODO> Need to write about how to install a couple of depenendent CSV files and
CustomResource objects, such as AMQ Interconnect, Elastic Cloud on Kubernetes,
and an instance of the Smart Gateway Operator.

### AMQ Certificate Manager

Install the `Subscription` for AMQ7 Certificate Manager. After creating the
`Subscription` you can validate your AMQ7 Certificate Manager is available by
running `oc get csv` and looking for the `amq7-cert-manager.v1.0.0` to have a
phase of `Succeeded`.

```
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq7-cert-manager
  namespace: openshift-operators
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: amq7-cert-manager
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: amq7-cert-manager.v1.0.0
EOF
```

## AMQ Interconnect

Install the `Subscription` for AMQ7 Interconnect Operator.

```
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq7-interconnect-operator
  namespace: service-telemetry
spec:
  channel: 1.2.0
  installPlanApproval: Automatic
  name: amq7-interconnect-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: amq7-interconnect-operator.v1.2.0
EOF
```

### InfraWatch Operators

Install the `OperatorSource` for InfraWatch. You can validate the installation
of the `OperatorSource` by running `oc get operatorsources -A` and looking for
`infrawatch-operators` status to have `Succeeded` and for it to have reconciled
successfully.

```
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  labels:
    opsrc-provider: infrawatch
  name: infrawatch-operators
  namespace: openshift-marketplace
spec:
  authorizationToken: {}
  displayName: InfraWatch Operators
  endpoint: https://quay.io/cnr
  publisher: InfraWatch
  registryNamespace: infrawatch
  type: appregistry
EOF
```

### Create a Smart Gateway Subscription

Create a Smart Gateway Operator subscription to complete the dependency tree of
the Service Telemetry Operator.

> **TIP**
>
> Alternatively you can follow the procedure to import a local Smart Gateway
> Operator build and `ClusterServiceVersion` by following the import procedure
> documented in the `README.md` of the Smart Gateway Operator at
> https://github.com/infrawatch/smart-gateway-operator.
>
> If you decide you want to use a local build of the Smart Gateway Operator and
> instantiate it with a CSV, then you don't need to create the `OperatorSource`
> from the previous step.
>
> You can delete the `OperatorSource` if necessary by running `oc delete
> -nopenshift-marketplace operatorsource infrawatch-operators`

```
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: smartgateway-operator
  namespace: service-telemetry
spec:
  channel: stable
  installPlanApproval: Automatic
  name: smartgateway-operator
  source: infrawatch-operators
  sourceNamespace: openshift-marketplace
  startingCSV: smart-gateway-operator.v1.0.0
EOF
```

## Deploy with the newly built operator

Install required RBAC rules and service account.

```
oc apply \
    -f deploy/role_binding.yaml \
    -f deploy/role.yaml \
    -f deploy/service_account.yaml \
    -f deploy/operator_group.yaml
```

Pick a version from `deploy/olm-catalog/service-telemetry-operator/` and run the
following commands. Adjust version to what you want to test. We'll be using
`v1.0.0` as our example version.

```
CSV_VERSION=1.0.0
INTERNAL_REGISTRY=$(oc registry info --internal=true)
oc apply -f deploy/olm-catalog/service-telemetry-operator/${CSV_VERSION}/infra.watch_servicetelemetrys_crd.yaml

oc apply -f <(sed "\
    s|image: .\+/service-telemetry-operator:.\+$|image: ${INTERNAL_REGISTRY}/service-telemetry/service-telemetry-operator:latest|g;
    s|namespace: placeholder|namespace: service-telemetry|g"\
    "deploy/olm-catalog/service-telemetry-operator/${CSV_VERSION}/service-telemetry-operator.v${CSV_VERSION}.clusterserviceversion.yaml")
```

Validate that installation of the `ClusterServiceVersion` is progressing via
the `oc` CLI console.

```
oc get csv --watch
```

If you see `PHASE: Succeeded` then your CSV has been properly imported and
your Operator should be running locally. You can validate this by running `oc
get pods` and looking for the `service-telemetry-operator` and that it is
`Running`.

You can bring up the logs of the Service Telemetry Operator by running `oc logs
<<pod_name>> -c operator`.

## Validate your installation

You can validate your installation by checking the status of objects in
OpenShift.

First, validate your CSVs have installed successfully.

```
oc get csv
NAME                                DISPLAY                                         VERSION   REPLACES                            PHASE
amq7-cert-manager.v1.0.0            Red Hat Integration - AMQ Certificate Manager   1.0.0                                         Succeeded
amq7-interconnect-operator.v1.2.0   Red Hat Integration - AMQ Interconnect          1.2.0                                         Succeeded
prometheusoperator.0.32.0           Prometheus Operator                             0.32.0    prometheusoperator.0.27.0           Succeeded
service-telemetry-operator.v1.0.0   Service Telemetry Operator                      1.0.0     service-telemetry-operator.v0.1.1   Succeeded
smart-gateway-operator.v1.0.0       Smart Gateway Operator                          1.0.0     smart-gateway-operator.v0.2.0       Succeeded
```

You can then validate the pods have all starts up successfully.

```
oc get pods
NAME                                          READY   STATUS    RESTARTS   AGE
interconnect-operator-69c86d84c-6pckc         1/1     Running   0          6m46s
prometheus-operator-8457f4964c-sqpsf          1/1     Running   0          6m54s
service-telemetry-operator-689bbc9c8c-w82sw   2/2     Running   0          6m54s
smart-gateway-operator-bcc4b9f7c-thpxs        2/2     Running   0          7m
```

## Creating a basic Service Telemetry deployment

You can quickly validate that things are working by creating a new
`ServiceTelemetry` object. In this case we're going to only be validating that
we can create a metrics consuming instance.

```
oc apply -f deploy/crds/infra.watch_v1alpha1_servicetelemetry_cr.yaml
```

You can validate all pods have come up successfully by running `oc get pods`.

```
oc get pods
NAME                                                           READY   STATUS    RESTARTS   AGE
alertmanager-stf-default-0                                     2/2     Running   0          40s
interconnect-operator-69c86d84c-6pckc                          1/1     Running   0          10m
prometheus-operator-8457f4964c-sqpsf                           1/1     Running   0          10m
prometheus-stf-default-0                                       3/3     Running   1          44s
service-telemetry-operator-689bbc9c8c-w82sw                    2/2     Running   0          10m
smart-gateway-operator-bcc4b9f7c-thpxs                         2/2     Running   0          11m
stf-default-collectd-telemetry-smartgateway-79c967c8f7-6mpc9   1/1     Running   0          26s
stf-default-interconnect-7458fd4d69-wbr4r                      1/1     Running   0          47s
```

You can also check the status of the `ServiceTelemetry` object we created by
running `oc get servicetelemetry stf-default -oyaml`.
