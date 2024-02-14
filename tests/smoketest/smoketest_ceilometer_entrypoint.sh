#!/bin/sh
set +e

# Executes inside the test harness container to start collectd and look for resulting metrics in prometheus
PROMETHEUS=${PROMETHEUS:-"https://default-prometheus-proxy:9092"}
ELASTICSEARCH=${ELASTICSEARCH:-"https://elasticsearch-es-http:9200"}
ELASTICSEARCH_AUTH_PASS=${ELASTICSEARCH_AUTH_PASS:-""}
PROMETHEUS_AUTH_TOKEN=${PROMETHEUS_AUTH_TOKEN:-""}
CLOUDNAME=${CLOUDNAME:-"smoke1"}
POD=$(hostname)


echo "*** [INFO] My pod is: ${POD}"

# Run ceilometer_publisher script
python3 /ceilometer_publish.py qdr-test:5672 'driver=amqp&topic=cloud1-metering' 'driver=amqp&topic=cloud1-event'

# Sleeping to produce data
echo "*** [INFO] Sleeping for 30 seconds to produce all metrics and events"
sleep 30

echo "*** [INFO] List of metric names for debugging..."
curl -sk -H "Authorization: Bearer ${PROMETHEUS_AUTH_TOKEN}" -g "${PROMETHEUS}/api/v1/label/__name__/values" 2>&2 | tee /tmp/label_names
echo; echo

# Checks that the metrics actually appear in prometheus
echo "*** [INFO] Checking for recent image metrics..."

echo "[DEBUG] Running the curl command to return a query"
curl -k -H "Authorization: Bearer ${PROMETHEUS_AUTH_TOKEN}" -g "${PROMETHEUS}/api/v1/query?" --data-urlencode 'query=ceilometer_image_size' 2>&1 | grep '"result":\[{"metric":{"__name__":"ceilometer_image_size"'
metrics_result=$?
echo "[DEBUG] Set metrics_result to $metrics_result"

if [ "$OBSERVABILITY_STRATEGY" != "use_redhat" ]; then
  echo "*** [INFO] Get documents for this test from ElasticSearch..."
  DOCUMENT_HITS=$(curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "${ELASTICSEARCH}/_search" -H 'Content-Type: application/json' -d'{
    "query": {
      "bool": {
        "filter": [
          { "term" : { "labels.instance" : { "value" : "'${CLOUDNAME}'", "boost" : 1.0 } } },
          { "range" : { "startsAt" : { "gte" : "now-1m", "lt" : "now" } } }
        ]
      }
    }
  }' | python3 -c "import sys, json; parsed = json.load(sys.stdin); print(parsed['hits']['total']['value'])")


  echo "*** [INFO] List of indices for debugging..."
  curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "${ELASTICSEARCH}/_cat/indices/ceilometer_*?s=index"
  echo

  echo "*** [INFO] Get documents for this test from ElasticSearch..."
  ES_INDEX=ceilometer_image
  DOCUMENT_HITS=$(curl -sk -u "elastic:${ELASTICSEARCH_AUTH_PASS}" -X GET "${ELASTICSEARCH}/${ES_INDEX}/_search" -H 'Content-Type: application/json' -d'{
    "query": {
      "match_all": {}
    }
  }'| python3 -c "import sys, json; parsed = json.load(sys.stdin); print(parsed['hits']['total']['value'])")

  echo "*** [INFO] Found ${DOCUMENT_HITS} documents"
  echo; echo

  # check if we got documents back for this test
  events_result=1
  if [ "$DOCUMENT_HITS" -gt "0" ]; then
      events_result=0
  fi
else
  events_result=0
fi

echo "[INFO] Verification exit codes (0 is passing, non-zero is a failure): events=${events_result} metrics=${metrics_result}"
echo; echo

if [ "$metrics_result" = "0" ] && [ "$events_result" = "0" ]; then
    echo "*** [INFO] Testing completed with success"
    exit 0
else
    echo "*** [INFO] Testing completed without success"
    exit 1
fi
