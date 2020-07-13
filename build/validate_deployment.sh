#!/usr/bin/env bash
set -e

# Play the (automated!) waiting game
echo -e "\n* [info] Waiting for QDR deployment to complete\n"
until timeout 300 oc rollout status deployment.apps/stf-default-interconnect; do sleep 3; done
echo -e "\n* [info] Waiting for prometheus deployment to complete\n"
until timeout 300 oc rollout status statefulset.apps/prometheus-stf-default; do sleep 3; done
echo -e "\n* [info] Waiting for elasticsearch deployment to complete \n"
while true; do
    sleep 3
    ES_READY=$(oc get statefulsets elasticsearch-es-default -ogo-template='{{ .status.readyReplicas }}') || continue
    if [ "${ES_READY}" == "1" ]; then
        break
    fi
done
echo -e "\n* [info] Waiting for alertmanager deployment to complete\n"
until timeout 300 oc rollout status statefulset.apps/alertmanager-stf-default; do sleep 3; done
echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
until timeout 300 oc rollout status deployment.apps/stf-default-collectd-telemetry-smartgateway; do sleep 3; done
until timeout 300 oc rollout status deployment.apps/stf-default-collectd-notification-smartgateway; do sleep 3; done
until timeout 300 oc rollout status deployment.apps/stf-default-ceilometer-notification-smartgateway; do sleep 3; done
until timeout 300 oc rollout status deployment.apps/stf-default-ceilometer-telemetry-smartgateway; do sleep 3; done
echo -e "\n* [info] Waiting for all pods to show Ready/Complete\n"
while oc get pods --selector '!openshift.io/build.name' | tail -n +2 | grep -v -E 'Running|Completed'; do
    sleep 3
done

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
