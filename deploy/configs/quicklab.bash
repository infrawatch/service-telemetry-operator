# NOTE: namespace is hardcoded because the namespace is embedded in the certs loaded by this configuration
KIND_SERVICETELEMETRY="apiVersion: infra.watch/v1alpha1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: service-telemetry
spec:
  metricsEnabled: true
  eventsEnabled: true
  storageEphemeralEnabled: true"
