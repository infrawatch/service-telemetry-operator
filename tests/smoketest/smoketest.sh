#!/bin/bash
#
# Runs on the dev/CI machine to execute the test harness job in the cluster
#
# Requires:
#   * oc tools pointing at your STF instance
#   * gnu sed
#
# Usage: ./smoketest.sh [NUMCLOUDS]
#
# NUMCLOUDS - how many clouds to simulate (that number of smart gateways and
# collectd pods will be created)

# Generate an array of cloud names to use
NUMCLOUDS=${1:-1}
CLOUDNAMES=()
for ((i=1; i<=NUMCLOUDS; i++)); do
  NAME="smoke${i}"
  CLOUDNAMES+=(${NAME})
done
REL=$(dirname "$0")

echo "*** [INFO] Getting ElasticSearch authentication password"
ELASTICSEARCH_AUTH_PASS=$(oc get secret elasticsearch-es-elastic-user -ogo-template='{{ .data.elastic | base64decode }}')

echo "*** [INFO] Creating configmaps..."
oc delete configmap/stf-smoketest-collectd-config configmap/stf-smoketest-entrypoint-script job/stf-smoketest || true
oc create configmap stf-smoketest-collectd-config --from-file ${REL}/minimal-collectd.conf.template
oc create configmap stf-smoketest-entrypoint-script --from-file ${REL}/smoketest_entrypoint.sh

echo "*** [INFO] Creating smoketest jobs..."
oc delete job -l app=stf-smoketest
for NAME in "${CLOUDNAMES[@]}"; do
    oc create -f <(sed -e "s/<<CLOUDNAME>>/${NAME}/;s/<<ELASTICSEARCH_AUTH_PASS>>/${ELASTICSEARCH_AUTH_PASS}/" ${REL}/smoketest_job.yaml.template)
done

# Trying to find a less brittle test than a timeout
JOB_TIMEOUT=300s
for NAME in "${CLOUDNAMES[@]}"; do
    echo "*** [INFO] Waiting on job/stf-smoketest-${NAME}..."
    oc wait --for=condition=complete --timeout=${JOB_TIMEOUT} "job/stf-smoketest-${NAME}"
    RET=$((RET || $?)) # Accumulate exit codes
done

echo "*** [INFO] Showing oc get all..."
oc get all
echo

echo "*** [INFO] Showing servicemonitors..."
oc get servicemonitor -o yaml
echo

echo "*** [INFO] Logs from smoketest containers..."
for NAME in "${CLOUDNAMES[@]}"; do
    oc logs "$(oc get pod -l "job-name=stf-smoketest-${NAME}" -o jsonpath='{.items[0].metadata.name}')"
done
echo

echo "*** [INFO] Logs from qdr..."
oc logs "$(oc get pod -l application=stf-default-interconnect -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from smart gateways..."
oc logs "$(oc get pod -l "smart-gateway=stf-default-collectd-telemetry" -o jsonpath='{.items[0].metadata.name}')"
oc logs "$(oc get pod -l "smart-gateway=stf-default-collectd-notification" -o jsonpath='{.items[0].metadata.name}')"
oc logs "$(oc get pod -l "smart-gateway=stf-default-ceilometer-notification" -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from smart gateway operator..."
oc logs "$(oc get pod -l app=smart-gateway-operator -o jsonpath='{.items[0].metadata.name}')" -c ansible
echo

echo "*** [INFO] Logs from prometheus..."
oc logs "$(oc get pod -l prometheus=stf-default -o jsonpath='{.items[0].metadata.name}')" -c prometheus
echo

echo "*** [INFO] Logs from elasticsearch..."
oc logs "$(oc get pod -l common.k8s.elastic.co/type=elasticsearch -o jsonpath='{.items[0].metadata.name}')"
echo

if [ $RET -eq 0 ]; then
    echo "*** [SUCCESS] Smoke test job completed successfully"
else
    echo "*** [FAILURE] Smoke test job still not succeeded after ${JOB_TIMEOUT}"
fi
echo

exit $RET
