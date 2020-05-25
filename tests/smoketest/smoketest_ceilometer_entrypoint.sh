#!/bin/sh
set -e

# Executes inside the test harness container to start collectd and look for resulting metrics in prometheus
PROMETHEUS=${PROMETHEUS:-"prometheus-operated:9090"}
ELASTICSEARCH=${ELASTICSEARCH:-"elasticsearch-es-http:9200"}
ELASTICSEARCH_AUTH_PASS=${ELASTICSEARCH_AUTH_PASS:-""}
CLOUDNAME=${CLOUDNAME:-"smoke1"}
POD=$(hostname)

# Install additional requirements for publisher scrip
pip install -r publisher/requirements.txt

echo "*** [INFO] My pod is: ${POD}"

# Run ceilometer_publisher script
python publisher/ceilometer_publish.py

# Sleeping to collect 1m of actual metrics
echo "*** [INFO] Sleeping for 20 seconds to collect metrics and events"
sleep 20

echo "*** [INFO] List of metric names for debugging..."
curl -g "${PROMETHEUS}/api/v1/label/__name__/values" 2>&2 | tee /tmp/label_names
echo; echo

echo "*** [INFO] Get documents for this test from ElasticSearch..."
DOCUMENT_HITS=$(curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "https://${ELASTICSEARCH}/_search" -H 'Content-Type: application/json' -d'{
  "query": {
    "bool": {
      "filter": [
        { "term" : { "labels.instance" : { "value" : "'${CLOUDNAME}'", "boost" : 1.0 } } },
        { "range" : { "startsAt" : { "gte" : "now-1m", "lt" : "now" } } }
      ]
    }
  }
}' | python3 -c "import sys, json; parsed = json.load(sys.stdin); print(parsed['hits']['total']['value'])")

echo "*** [INFO] Found ${DOCUMENT_HITS} documents"
echo; echo

# check if we got documents back for this test
events_result=1
if [ "$DOCUMENT_HITS" -gt "0" ]; then
    events_result=0
fi

if [ "$metrics_result" = "0" ] && [ "$events_result" = "0" ]; then
    echo "*** [INFO] Testing completed with success"
    exit 0
else
    echo "*** [INFO] Testing completed without success"
    exit 1
fi
