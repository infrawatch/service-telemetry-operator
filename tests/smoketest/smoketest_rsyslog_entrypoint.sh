#!/bin/sh
set -e

ELASTICSEARCH=${ELASTICSEARCH:-"elasticsearch-es-http:9200"}
ELASTICSEARCH_AUTH_PASS=${ELASTICSEARCH_AUTH_PASS:-""}
LOKI=${LOKI:-"loki-query-frontend-http-lokistack:3100"}
INGESTER=${INGESTER:-"loki-ingester-http-lokistack:3100"}
CLOUDNAME=${CLOUDNAME:-"smoke1"}
CURRENT_TIME=`date -d now +%s`000000000
CONTROL_LOG_MSG="logmessage"$CURRENT_TIME
QUERY="http://${LOKI}/loki/api/v1/query_range --data-urlencode 'query={cloud=\""$CLOUDNAME"\"}'"

echo "*** [INFO] Generating logs"
touch /tmp/test.log
while true
do
  echo "[$(date +'%Y-%m-%d %H:%M')] WARNING Something bad might happen" >> /tmp/test.log
  echo "[$(date +'%Y-%m-%d %H:%M')] :ERROR: Something bad happened" >> /tmp/test.log
  echo "[$(date +'%Y-%m-%d %H:%M')] [DEBUG] Wubba lubba dub dub" >> /tmp/test.log
  echo $CONTROL_LOG_MSG >> /tmp/test.log
  sleep 10
done &
echo

echo "*** [INFO] Running rsyslog"
rsyslogd -n &
echo

echo "*** [INFO] Sleeping for 30 seconds to give enough time for logs to get to Loki"
sleep 30s
echo

echo "*** [INFO] Flushing the in-memory chunks"
curl -XPOST -s "http://${INGESTER}/flush"
sleep 10s
echo

echo "*** [INFO] Generated logfile for debugging"
cat /tmp/test.log
echo; echo

echo "*** [INFO] List of labels for debugging..."
curl -s "http://${LOKI}/loki/api/v1/labels"
echo

echo "*** [INFO] Get logs for this test from Loki..."
LOGS=$(curl -Gs "http://${LOKI}/loki/api/v1/query_range" --data-urlencode "query={cloud=\"${CLOUDNAME}\"}")
echo

echo "*** [INFO] Logs returned from Loki"
echo "${LOGS}"
echo

LOG_COUNT=`echo "${LOGS}" | grep -c ${CONTROL_LOG_MSG} || true`

# check if we got logs back for this test
logs_result=1
if [ "$LOG_COUNT" -ge "1" ]; then
    logs_result=0
fi

echo "[INFO] Verification exit codes (0 is passing, non-zero is a failure): logs=${logs_result}"
echo; echo

if [ "$logs_result" = "0" ]; then
    echo "*** [INFO] Testing completed with success"
    exit 0
else
    echo "*** [INFO] Testing completed without success"
    exit 1
fi
