#!/bin/bash
#
# Runs on the dev/CI machine to execute the test harness job in the cluster
#
# Requires:
#   * oc tools pointing at your STF instance
#   * gnu sed
#
# Usage: CLEANUP=<bool> NUMCLOUDS=<num clouds> OCP_PROJECT=<project> ./smoketest.sh
#
# CLEANUP - cleanup smoketest resources once test finishes (default: true)
# NUMCLOUDS - how many clouds to simulate (that number of smart gateways and
# OCP_PROJECT - namespace you wish to use. Defaults to current
# collectd pods will be created)

# Generate an array of cloud names to use
NUMCLOUDS=${NUMCLOUDS:-1}
CLOUDNAMES=()
OCP_PROJECT=${OCP_PROJECT:-}
OC_CLIENT_VERSION_X=$(oc version --client | grep Client | cut -f2 -d: | tr -s -d "[:space:]" - | cut -d. -f1)
OC_CLIENT_VERSION_X_REQUIRED=4
OC_CLIENT_VERSION_Y=$(oc version --client | grep Client | cut -f2 -d: | tr -s -d "[:space:]" - | cut -d. -f2)
OC_CLIENT_VERSION_Y_REQUIRED=10

if [ "${OC_CLIENT_VERSION_Y}" -lt "${OC_CLIENT_VERSION_Y_REQUIRED}" ] || [ "${OC_CLIENT_VERSION_X}" != "${OC_CLIENT_VERSION_X_REQUIRED}" ]; then
    echo "*** Please install 'oc' client version ${OC_CLIENT_VERSION_X_REQUIRED}.${OC_CLIENT_VERSION_Y_REQUIRED} or later ***"
    exit 1
fi

if [ "$(oc get stf default -o=jsonpath='{.spec.transports.qdr.auth}')" != "none" ]; then
    echo "*** QDR authentication is currently not supported in smoketests."
    echo "To disable it, use: oc patch stf default --patch '{\"spec\":{\"transports\":{\"qdr\":{\"auth\":\"none\"}}}}' --type=merge"
    echo "For more info: https://github.com/infrawatch/service-telemetry-operator/pull/492"
    exit 1
fi

CLEANUP=${CLEANUP:-true}
SMOKETEST_VERBOSE=${SMOKETEST_VERBOSE:-true}

for ((i=1; i<=NUMCLOUDS; i++)); do
  NAME="smoke${i}"
  CLOUDNAMES+=("${NAME}")
done
REL=$(dirname "$0")

if [ -n "${OCP_PROJECT}" ]; then
    oc project "$OCP_PROJECT"
else
    OCP_PROJECT=$(oc project -q)
fi

echo "*** [INFO] Working in project ${OCP_PROJECT}"

echo "*** [INFO] Getting ElasticSearch authentication password"
ELASTICSEARCH_AUTH_PASS=$(oc get secret elasticsearch-es-elastic-user -ogo-template='{{ .data.elastic | base64decode }}')

echo "*** [INFO] Getting Prometheus authentication password"
PROMETHEUS_AUTH_PASS=$(oc get secret default-prometheus-htpasswd -ogo-template='{{ .data.password | base64decode }}')

echo "*** [INFO] Setting namepsace for collectd-sensubility config"
sed "s/<<NAMESPACE>>/${OCP_PROJECT}/g" "${REL}/collectd-sensubility.conf" > /tmp/collectd-sensubility.conf

echo "*** [INFO] Creating configmaps..."
oc delete configmap/stf-smoketest-healthcheck-log configmap/stf-smoketest-collectd-config configmap/stf-smoketest-sensubility-config configmap/stf-smoketest-collectd-entrypoint-script configmap/stf-smoketest-ceilometer-publisher configmap/stf-smoketest-ceilometer-entrypoint-script job/stf-smoketest || true
oc create configmap stf-smoketest-healthcheck-log --from-file "${REL}/healthcheck.log"
oc create configmap stf-smoketest-collectd-config --from-file "${REL}/minimal-collectd.conf.template"
oc create configmap stf-smoketest-sensubility-config --from-file /tmp/collectd-sensubility.conf
oc create configmap stf-smoketest-collectd-entrypoint-script --from-file "${REL}/smoketest_collectd_entrypoint.sh"
oc create configmap stf-smoketest-ceilometer-publisher --from-file "${REL}/ceilometer_publish.py"
oc create configmap stf-smoketest-ceilometer-entrypoint-script --from-file "${REL}/smoketest_ceilometer_entrypoint.sh"

echo "*** [INFO] Creating smoketest jobs..."
oc delete job -l app=stf-smoketest
for NAME in "${CLOUDNAMES[@]}"; do
    oc create -f <(sed -e "s/<<CLOUDNAME>>/${NAME}/;s/<<ELASTICSEARCH_AUTH_PASS>>/${ELASTICSEARCH_AUTH_PASS}/;s/<<PROMETHEUS_AUTH_PASS>>/${PROMETHEUS_AUTH_PASS}/" ${REL}/smoketest_job.yaml.template)
done

echo "*** [INFO] Triggering an alertmanager notification..."

# check if the oc client version is less than 4.11 and adjust the token command to match available commands
if [ 0${OC_CLIENT_VERSION_Y} -lt 011 ]; then
    PROMETHEUS_K8S_TOKEN=$(oc serviceaccounts get-token prometheus-stf)
else
    PROMETHEUS_K8S_TOKEN=$(oc create token prometheus-stf)
fi

# create the alert using startsAt which in theory may cause trigger to be faster
echo "*** [INFO] Create alert"
oc delete pod -l run=curl ; oc run curl --wait --restart='Never' --image=quay.io/infrawatch/busyboxplus:curl -- sh -c "curl -v -k -H \"Content-Type: application/json\" -H \"Authorization: Bearer ${PROMETHEUS_K8S_TOKEN}\" -d '[{\"status\":\"firing\",\"labels\":{\"alertname\":\"smoketest\",\"severity\":\"warning\"},\"startsAt\":\"$(date --rfc-3339=seconds | sed 's/ /T/')\"}]' https://default-alertmanager-proxy:9095/api/v1/alerts"
oc wait --for=jsonpath='{.status.phase}'=Succeeded pod/curl
oc logs curl

echo "*** [INFO] Waiting to see SNMP trap message in webhook pod"
SNMP_WEBHOOK_POD=$(oc get pod -l "app=default-snmp-webhook" -ojsonpath='{.items[0].metadata.name}')
SNMP_WEBHOOK_CHECK_MAX_TRIES=5
SNMP_WEBHOOK_CHECK_TIMEOUT=30
SNMP_WEBHOOK_CHECK_COUNT=0
while [ $SNMP_WEBHOOK_CHECK_COUNT -lt $SNMP_WEBHOOK_CHECK_MAX_TRIES ]; do
    oc logs "$SNMP_WEBHOOK_POD" | grep 'Sending SNMP trap'
    SNMP_WEBHOOK_STATUS=$?
    (( SNMP_WEBHOOK_CHECK_COUNT=SNMP_WEBHOOK_CHECK_COUNT+1 ))
    if [ $SNMP_WEBHOOK_STATUS -eq 0 ]; then
        break
    fi
    sleep $SNMP_WEBHOOK_CHECK_TIMEOUT
done

# Trying to find a less brittle test than a timeout
JOB_TIMEOUT=300s
for NAME in "${CLOUDNAMES[@]}"; do
    echo "*** [INFO] Waiting on job/stf-smoketest-${NAME}..."
    oc wait --for=condition=complete --timeout=${JOB_TIMEOUT} "job/stf-smoketest-${NAME}"
    RET=$((RET || $?)) # Accumulate exit codes
done

echo "*** [INFO] Checking that the qdr certificate has a long expiry"
EXPIRETIME=$(oc get secret default-interconnect-openstack-ca -o json | grep \"tls.crt\"\: | awk -F '": "' '{print $2}' | rev | cut -c3- | rev | base64 -d | openssl x509 -text | grep "Not After" | awk -F " : " '{print $2}')
EXPIRETIME_UNIX=$(date -d "${EXPIRETIME}" "+%s")
TARGET_UNIX=$(date -d "now + 7 years" "+%s")
if [ ${EXPIRETIME_UNIX} -lt ${TARGET_UNIX} ]; then
    echo "[FAILURE] Certificate expire time (${EXPIRETIME}) less than 7 years from now"
fi

echo "*** [INFO] Showing oc get all..."
oc get all
echo

echo "*** [INFO] Showing servicemonitors..."
oc get servicemonitors.monitoring.rhobs -o yaml
echo

if [ "$SMOKETEST_VERBOSE" = "true" ]; then
    echo "*** [INFO] Logs from smoketest containers..."
        for NAME in "${CLOUDNAMES[@]}"; do
            oc logs "$(oc get pod -l "job-name=stf-smoketest-${NAME}" -o jsonpath='{.items[0].metadata.name}')" -c smoketest-collectd
            oc logs "$(oc get pod -l "job-name=stf-smoketest-${NAME}" -o jsonpath='{.items[0].metadata.name}')" -c smoketest-ceilometer
        done
    echo

    echo "*** [INFO] Logs from qdr..."
    oc logs "$(oc get pod -l application=default-interconnect -o jsonpath='{.items[0].metadata.name}')"
    echo

    echo "*** [INFO] Logs from smart gateways..."
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-coll-meter" -o jsonpath='{.items[0].metadata.name}')" -c bridge
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-coll-meter" -o jsonpath='{.items[0].metadata.name}')" -c sg-core
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-coll-event" -o jsonpath='{.items[0].metadata.name}')" -c bridge
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-coll-event" -o jsonpath='{.items[0].metadata.name}')" -c sg-core
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-ceil-meter" -o jsonpath='{.items[0].metadata.name}')" -c bridge
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-ceil-meter" -o jsonpath='{.items[0].metadata.name}')" -c sg-core
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-ceil-event" -o jsonpath='{.items[0].metadata.name}')" -c bridge
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-ceil-event" -o jsonpath='{.items[0].metadata.name}')" -c sg-core
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-sens-meter" -o jsonpath='{.items[0].metadata.name}')" -c bridge
    oc logs "$(oc get pod -l "smart-gateway=default-cloud1-sens-meter" -o jsonpath='{.items[0].metadata.name}')" -c sg-core
    echo

    echo "*** [INFO] Logs from smart gateway operator..."
    oc logs "$(oc get pod -l app=smart-gateway-operator -o jsonpath='{.items[0].metadata.name}')"
    echo

    echo "*** [INFO] Logs from prometheus..."
    oc logs "$(oc get pod -l prometheus=default -o jsonpath='{.items[0].metadata.name}')" -c prometheus
    echo

    echo "*** [INFO] Logs from elasticsearch..."
    oc logs "$(oc get pod -l common.k8s.elastic.co/type=elasticsearch -o jsonpath='{.items[0].metadata.name}')"
    echo

    echo "*** [INFO] Logs from snmp webhook..."
    oc logs "$(oc get pod -l app=default-snmp-webhook -o jsonpath='{.items[0].metadata.name}')"
    echo

    echo "*** [INFO] Logs from alertmanager..."
    oc logs "$(oc get pod -l app.kubernetes.io/name=alertmanager -o jsonpath='{.items[0].metadata.name}')" -c alertmanager
    echo
fi

echo "*** [INFO] Cleanup resources..."
if $CLEANUP; then
    oc delete "job/stf-smoketest-${NAME}"
    # resolve the alert to clean up the system, otherwise this expires in 5 minutes
    oc delete pod -l run=curl ; oc run curl --restart='Never' --image=quay.io/infrawatch/busyboxplus:curl -- sh -c "curl -v -k -H \"Content-Type: application/json\" -H \"Authorization: Bearer ${PROMETHEUS_K8S_TOKEN}\" -d '[{\"status\":\"firing\",\"labels\":{\"alertname\":\"smoketest\",\"severity\":\"warning\"},\"startsAt\":\"$(date --rfc-3339=seconds | sed 's/ /T/')\",\"endsAt\":\"$(date --rfc-3339=seconds | sed 's/ /T/')\"}]' https://default-alertmanager-proxy:9095/api/v1/alerts"
fi
echo

if [ $RET -eq 0 ] && [ $SNMP_WEBHOOK_STATUS -eq 0 ]; then
    echo "*** [SUCCESS] Smoke test job completed successfully"
    exit 0
else
    echo "*** [FAILURE] Smoke test job still not succeeded after ${JOB_TIMEOUT}"
    exit 1
fi
