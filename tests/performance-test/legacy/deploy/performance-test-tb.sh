#!/bin/bash

COUNT=${COUNT:-180}
HOSTS=${HOSTS:-20}
PLUGINS=${PLUGINS:-1000}
INTERVAL=${INTERVAL:-1}
CONCURRENT=${CONCURRENT:-1}

oc delete job -l app=stf-performance-test || true

oc delete configmap/stf-performance-test-collectd-config \
          configmap/stf-performance-test-events-entry \
          job/stf-perftest-notify || true

oc create configmap stf-performance-test-collectd-config --from-file \
        ./config/minimal-collectd.conf

oc create configmap stf-performance-test-events-entry --from-file \
          ./entrypoint.sh
          
oc create -f ./performance-test-job-events.yml.template

for i in $(seq 1 ${CONCURRENT}); do
   oc create -f <(sed  -e "s/<<PREFIX>>/stf-perftest-${i}-/g;
                           s/<<COUNT>>/${COUNT}/g;
                           s/<<HOSTS>>/${HOSTS}/g;
                           s/<<PLUGINS>>/${PLUGINS}/g;
                           s/<<INTERVAL>>/${INTERVAL}/g"\
                           performance-test-job-tb.yml.template)
done
