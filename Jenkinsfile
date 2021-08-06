#!/usr/bin/env groovy

// can't just use BUILD_TAG because qdr operator limits name of resources to 60 chars
def namespace = env.JOB_BASE_NAME + '-' + env.BUILD_NUMBER
namespace = namespace.toLowerCase()

def stages_failed = false;

def stf_resource = """
apiVersion: infra.watch/v1beta1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: ${namespace}
spec:
  alerting:
    alertmanager:
      storage:
        strategy: ephemeral
      receivers:
        snmpTraps:
          enabled: true
  backends:
    events:
      elasticsearch:
        enabled: true
        storage:
          strategy: ephemeral
    metrics:
      prometheus:
        enabled: true
        storage:
          strategy: ephemeral
  transports:
    qdr:
      enabled: true
      deployment_size: 1
      web:
        enabled: false
  elasticsearch_manifest: |
    apiVersion: elasticsearch.k8s.elastic.co/v1beta1
    kind: Elasticsearch
    metadata:
      name: elasticsearch
      namespace: $namespace
    spec:
      version: 7.10.2
      http:
        tls:
          certificate:
            secretName: 'elasticsearch-es-cert'
      nodeSets:
        - config:
            node.data: true
            node.ingest: true
            node.master: true
            node.store.allow_mmap: true
          count: 1
          name: default
          podTemplate:
            metadata:
              labels:
                tuned.openshift.io/elasticsearch: elasticsearch
            spec:
              containers:
                - name: elasticsearch
                  resources:
                    limits:
                      cpu: '2'
                      memory: 4Gi
                    requests:
                      cpu: '1'
                      memory: 2Gi
              volumes:
                - emptyDir: {}
                  name: elasticsearch-data
"""

podTemplate(containers: [
    containerTemplate(
        cloud: 'openshift',
        name: 'exec',
        image: 'image-registry.openshift-image-registry.svc:5000/ci/jenkins-agent:latest',
        command: 'sleep',
        args: 'infinity',
        alwaysPullImage: true
    )],
    serviceAccount: 'jenkins-operator-cloudops'

) {
    node(POD_LABEL) {
        container('exec') {
            dir('service-telemetry-operator') {
                stage ('Clone Upstream') {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        checkout scm
                    }
                }
                stage ('Create project') {
                    if ( currentBuild.result == 'FAILURE' ) { stages_failed = true; return; }
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        openshift.withCluster(){
                            openshift.newProject(namespace)
                        }
                    }
                }
                stage('Build STF Containers') {
                    if ( currentBuild.result == 'FAILURE' ) { stages_failed = true; return; }
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        ansiColor('xterm') {
                            ansiblePlaybook(
                                playbook: 'build/run-ci.yaml',
                                colorized: true,
                                extraVars: [
                                    "namespace": namespace,
                                    "__deploy_stf": "false",
                                    "__local_build_enabled": "true",
                                    "__service_telemetry_snmptraps_enabled": "true",
                                    "__service_telemetry_storage_ephemeral_enabled": "true"
                                ]
                            )
                        }
                    }
                }
                stage('Deploy STF Object') {
                    if ( currentBuild.result == 'FAILURE' ) { stages_failed = true; return; }
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        openshift.withCluster() {
                            openshift.withProject(namespace) {
                                openshift.create(stf_resource)
                                sh "OCP_PROJECT=${namespace} ./build/validate_deployment.sh"
                            }
                        }
                    }
                }
                stage('Run Smoketest') {
                    if ( currentBuild.result == 'FAILURE' ) { stages_failed = true; return; }
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        sh "OCP_PROJECT=${namespace} ./tests/smoketest/smoketest.sh"
                    }
                }
                stage('Cleanup') {
                    openshift.withCluster(){
                        openshift.selector("project/${namespace}").delete()
                        if ( stages_failed ) { currentBuild.result = 'FAILUR' }
                    }
                    if ( stages_failed ) { curreentBuild.result = 'FAILURE' }
                }
            }
        }
    }
}

