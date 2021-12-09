#!/usr/bin/env bash
set -e

if [ -n "${OCP_PROJECT+x}" ]; then
    oc project "$OCP_PROJECT"
fi

VALIDATION_SCOPE="${VALIDATION_SCOPE:-use_community}"

# Play the (automated!) waiting game
echo -e "\n* [info] Waiting for QDR deployment to complete\n"
until timeout 300 oc rollout status deployment.apps/default-interconnect; do sleep 3; done

case "${VALIDATION_SCOPE}" in
    "use_community")
        echo -e "\n* [info] Waiting for prometheus deployment to complete\n"
        until timeout 300 oc rollout status statefulset.apps/prometheus-default; do sleep 3; done
		echo -e "\n* [info] Waiting for loki deployment to complete\n"
		until timeout 300 oc rollout status statefulset.apps/loki-compactor-lokistack; do sleep 3; done
		until timeout 300 oc rollout status statefulset.apps/loki-ingester-lokistack; do sleep 3; done
		until timeout 300 oc rollout status statefulset.apps/loki-querier-lokistack; do sleep 3; done
		until timeout 300 oc rollout status deployment.apps/loki-distributor-lokistack; do sleep 3; done
		until timeout 300 oc rollout status deployment.apps/loki-query-frontend-lokistack; do sleep 3; done
		# For some reason loki ingester waits a minute until it becomes ready after startup
		echo -e "\n* [info] Waiting for loki ingester to be ready\n"
		sleep 60
        echo -e "\n* [info] Waiting for elasticsearch deployment to complete \n"
        while true; do
            sleep 3
            ES_READY=$(oc get statefulsets elasticsearch-es-default -ogo-template='{{ .status.readyReplicas }}') || continue
            if [ "${ES_READY}" == "1" ]; then
                break
            fi
        done
        echo -e "\n* [info] Waiting for alertmanager deployment to complete\n"
        until timeout 300 oc rollout status statefulset.apps/alertmanager-default; do sleep 3; done
        echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
        until timeout 300 oc rollout status deployment.apps/default-cloud1-coll-meter-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-coll-event-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-ceil-event-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-ceil-meter-smartgateway; do sleep 3; done
		until timeout 300 oc rollout status deployment.apps/default-cloud1-rsys-log-smartgateway; do sleep 3; done
    ;;

    "none")
        echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
        until timeout 300 oc rollout status deployment.apps/default-cloud1-coll-meter-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-ceil-meter-smartgateway; do sleep 3; done
    ;;
esac
echo -e "\n* [info] Waiting for all pods to show Ready/Complete\n"
while oc get pods --selector '!openshift.io/build.name' | tail -n +2 | grep -v -E 'Running|Completed'; do
    sleep 3
done

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
