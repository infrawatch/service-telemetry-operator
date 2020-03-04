# NOTE: namespace is hardcoded because the namespace is embedded in the certs loaded by this configuration
KIND_SERVICEASSURANCE="apiVersion: infra.watch/v1alpha1
kind: ServiceTelemetry
metadata:
  name: stf-default
  namespace: service-telemetry
spec:
  metricsEnabled: true
  eventsEnabled: true
  alertmanager_manifest: |
    apiVersion: monitoring.coreos.com/v1
    kind: Alertmanager
    metadata:
      labels:
        alertmanager: stf-default
      name: stf-default
      namespace: service-telemetry
    spec:
      replicas: 1
      serviceAccountName: prometheus-k8s
      serviceMonitorSelector:
        matchLabels:
          app: smart-gateway
  prometheus_manifest: |
    apiVersion: monitoring.coreos.com/v1
    kind: Prometheus
    metadata:
      labels:
        prometheus: stf-default
      name: stf-default
      namespace: service-telemetry
    spec:
      replicas: 1
      ruleSelector: {}
      securityContext: {}
      serviceAccountName: prometheus-k8s
      serviceMonitorSelector:
        matchLabels:
          app: smart-gateway
  elasticsearch_manifest: |
    apiVersion: elasticsearch.k8s.elastic.co/v1beta1
    kind: Elasticsearch
    metadata:
      name: elasticsearch
      namespace: service-telemetry
    spec:
      http:
        service:
          metadata:
            creationTimestamp: null
          spec: {}
        tls:
          certificate:
            secretName: elasticsearch-es-cert
      nodeSets:
        - config:
            node.data: true
            node.ingest: true
            node.master: true
            node.store.allow_mmap: false
          count: 1
          name: default
          podTemplate:
            spec:
              containers:
                - name: elasticsearch
                  resources:
                    limits:
                      cpu: '2'
                      memory: 4Gi
                    requests:
                      cpu: '1'
                      memory: 4Gi
              volumes:
                - emptyDir: {}
                  name: elasticsearch-data
      version: 7.5.1"
