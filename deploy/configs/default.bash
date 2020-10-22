KIND_SERVICETELEMETRY="apiVersion: infra.watch/v1alpha1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: ${OCP_PROJECT}
spec:
  metricsEnabled: true
  eventsEnabled: true"
