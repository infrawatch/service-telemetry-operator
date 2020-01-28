KIND_SERVICEASSURANCE="apiVersion: infra.watch/v1alpha1
kind: ServiceAssurance
metadata:
  name: saf-default
  namespace: ${OCP_PROJECT}
spec:
  metricsEnabled: true
  eventsEnabled: false"
