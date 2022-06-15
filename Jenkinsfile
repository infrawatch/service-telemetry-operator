#!/usr/bin/env groovy


def tested_files = "build/.*|deploy/.*|roles/.*|tests/smoketest/.*|Makefile|watches.yaml|Jenkinsfile"

// can't just use BUILD_TAG because qdr operator limits name of resources to 60 chars
def namespace = env.JOB_BASE_NAME + '-' + env.BUILD_NUMBER
namespace = namespace.toLowerCase()
namespace = namespace.replaceAll('\\.', '-')

def stf_resource = """
apiVersion: infra.watch/v1beta1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: ${namespace}
spec:
  observabilityStrategy: use_community
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
      deploymentSize: 1
      web:
        enabled: false
  elasticsearchManifest: |
    apiVersion: elasticsearch.k8s.elastic.co/v1
    kind: Elasticsearch
    metadata:
      name: elasticsearch
      namespace: $namespace
    spec:
      version: 7.16.1
      volumeClaimDeletePolicy: DeleteOnScaledownAndClusterDeletion
      http:
        tls:
          certificate:
            secretName: 'elasticsearch-es-cert'
      nodeSets:
        - config:
            node.roles:
              - master
              - data
              - ingest
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
                      memory: 2Gi
                    requests:
                      cpu: '1'
                      memory: 1Gi
              volumes:
                - emptyDir: {}
                  name: elasticsearch-data
"""

def working_branch = "master"

pipeline {
	agent {
		kubernetes {
			inheritFrom 'ocp-agent'
			defaultContainer 'exec'
		}
	}
	stages {
		stage('Clone Upstream') {
			when {
				changeset pattern: "${tested_files}", comparator: "REGEXP"
			}
			steps {
				dir('service-telemetry-operator') {
					catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
						checkout scm
						script {
							working_branch = sh(script: 'git ls-remote --heads origin | grep $(git rev-parse HEAD) | cut -d / -f 3', returnStdout: true).toString().trim()
							if (!working_branch) {
								// in this case, a merge with the base branch was required thus we use the second to last commit
								// to find the original topic branch name
								working_branch = sh(script: 'git ls-remote --heads origin | grep $(git rev-parse HEAD~1) | cut -d / -f 3', returnStdout: true).toString().trim()
							}
						}
						sh "git checkout -b ${working_branch}"
					}
				}
			}
		}
		stage('Create project') {
			when {
				expression {
					currentBuild.result == null
				}
				changeset pattern: "${tested_files}", comparator: "REGEXP"
			}
			steps {
				dir('service-telemetry-operator') {
					catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
						script {
							openshift.withCluster() {
								openshift.newProject(namespace)
							}
						}
					}
				}
			}
		}
		stage('Build STF Containers') {
			when {
				expression {
					currentBuild.result == null
				}
				changeset pattern: "${tested_files}", comparator: "REGEXP"
			}
			steps {
				dir('service-telemetry-operator') {
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
									"__service_telemetry_storage_ephemeral_enabled": "true",
									"working_branch":"${working_branch}"
								]
							)
						}
					}
				}
			}
		}
		stage('Deploy STF Object') {
			when {
				expression {
					currentBuild.result == null
				}
				changeset pattern: "${tested_files}", comparator: "REGEXP"
			}
			steps {
				dir('service-telemetry-operator') {
					catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
						script {
							openshift.withCluster() {
								openshift.withProject(namespace) {
									timeout(time: 800, unit: 'SECONDS') {
										openshift.create(stf_resource)
										sh "OCP_PROJECT=${namespace} ./build/validate_deployment.sh"
									}
								}
							}
						}
					}
				}
			}
		}
		stage('Run Smoketest') {
			when {
				expression {
					currentBuild.result == null
				}
				changeset pattern: "${tested_files}", comparator: "REGEXP"
			}
			steps {
				dir('service-telemetry-operator') {
					catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
						sh "OCP_PROJECT=${namespace} ./tests/smoketest/smoketest.sh"
					}
				}
			}
		}
		stage('Cleanup') {
			when {
				changeset pattern: "${tested_files}", comparator: "REGEXP"
			}
			steps {
				dir('service-telemetry-operator') {
					script {
						openshift.withCluster(){
							openshift.selector("project/${namespace}").delete()
						}
					}
				}
			}
			post {
				always {
					script {
						if ( currentBuild.result != null && currentBuild.result != 'SUCCESS' ) {
							currentBuild.result = 'FAILURE'
						}
					}
				}
			}
		}
	}
}
