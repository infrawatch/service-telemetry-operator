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
python3 /ceilometer_publish.py stf-default-interconnect:5672 driver=amqp&topic=metric driver=amqp&topic=event

# Sleeping to produce data
echo "*** [INFO] Sleeping for 20 seconds to produce all metrics and events"
sleep 20

echo "*** [INFO] List of metric names for debugging..."
curl -s -g "${PROMETHEUS}/api/v1/label/__name__/values" 2>&2 | tee /tmp/label_names
echo; echo

#TODO: Verify existance of ceilometer metrics

echo "*** [INFO] List of indices for debugging..."
curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "https://${ELASTICSEARCH}/_cat/indices/ceilometer_*?s=index"
echo

echo "*** [INFO] Get documents for this test from ElasticSearch..."
ES_INDEX=$(curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "https://${ELASTICSEARCH}/_cat/indices/ceilometer_*" | cut -d' ' -f3)
DOCUMENT_HITS=$(curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "https://${ELASTICSEARCH}/${ES_INDEX}/_search" -H 'Content-Type: application/json' -d'{
  "query": {
    "match_all": {}
  }
}' | python3 -c "import sys, json; parsed = json.load(sys.stdin); print(parsed['hits']['total']['value'])")

echo "*** [INFO] Found ${DOCUMENT_HITS} documents"
echo; echo
