#!/bin/sh
set -e

# Executes inside the test harness container to start collectd and look for resulting metrics in prometheus
PROMETHEUS=${PROMETHEUS:-"prometheus-operated:9090"}
ELASTICSEARCH=${ELASTICSEARCH:-"elasticsearch-es-http:9200"}
ELASTICSEARCH_AUTH_PASS=${ELASTICSEARCH_AUTH_PASS:-""}
CLOUDNAME=${CLOUDNAME:-"smoke1"}
POD=$(hostname)


echo "*** [INFO] My pod is: ${POD}"

# Run ceilometer_publisher script
python3 /ceilometer_publish.py stf-default-interconnect:5672 driver=amqp&topic=metric

# Sleeping to produce data
echo "*** [INFO] Sleeping for 20 seconds to produce all metrics and events"
sleep 20

echo "*** [INFO] List of metric names for debugging..."
curl -s -g "${PROMETHEUS}/api/v1/label/__name__/values" 2>&2 | tee /tmp/label_names
echo; echo

echo "*** [INFO] List of indices for debugging..."
curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "https://${ELASTICSEARCH}/_cluster/health"
echo; echo
curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "https://${ELASTICSEARCH}/_cat/indices"
echo; echo

