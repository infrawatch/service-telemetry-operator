#!/bin/bash
#
# Runs on the dev/CI machine to execute the test harness job in the cluster
#
# Requires:
#   * oc tools pointing at your SAF instance
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

echo "*** [INFO] Creating configmaps..."
oc delete configmap/saf-smoketest-collectd-config configmap/saf-smoketest-entrypoint-script job/saf-smoketest || true
oc create configmap saf-smoketest-collectd-config --from-file ./minimal-collectd.conf.template
oc create configmap saf-smoketest-entrypoint-script --from-file ./smoketest_entrypoint.sh

echo "*** [INFO] Creating smoketest jobs..."
oc delete job -l app=saf-smoketest
for NAME in "${CLOUDNAMES[@]}"; do
    oc create -f <(sed -e "s/<<CLOUDNAME>>/${NAME}/" smoketest_job.yaml.template)
done

# Trying to find a less brittle test than a timeout
JOB_TIMEOUT=300s
for NAME in "${CLOUDNAMES[@]}"; do
    echo "*** [INFO] Waiting on job/saf-smoketest-${NAME}..."
    oc wait --for=condition=complete --timeout=${JOB_TIMEOUT} "job/saf-smoketest-${NAME}"
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
    oc logs "$(oc get pod -l "job-name=saf-smoketest-${NAME}" -o jsonpath='{.items[0].metadata.name}')"
done
echo

echo "*** [INFO] Logs from qdr..."
oc logs "$(oc get pod -l application=saf-default-interconnect -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from smart gateways..."
oc logs "$(oc get pod -l "deploymentconfig=saf-default-telemetry-smartgateway" -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from smart gateway operator..."
oc logs "$(oc get pod -l app=smart-gateway -o jsonpath='{.items[0].metadata.name}')" -c ansible
echo

echo "*** [INFO] Logs from prometheus..."
oc logs "$(oc get pod -l prometheus=saf-default -o jsonpath='{.items[0].metadata.name}')" -c prometheus
echo

echo "*** [INFO] Logs from elasticsearch..."
oc logs "$(oc get pod -l component=elasticsearch -o jsonpath='{.items[0].metadata.name}')" -c elasticsearch
echo

if [ $RET -eq 0 ]; then
    echo "*** [SUCCESS] Smoke test job completed successfully"
else
    echo "*** [FAILURE] Smoke test job still not succeeded after ${JOB_TIMEOUT}"
fi
echo

exit $RET
