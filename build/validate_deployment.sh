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
    "use_community" | "use_hybrid")
        echo -e "\n* [info] Waiting for prometheus deployment to complete\n"
        until timeout 300 oc rollout status statefulset.apps/prometheus-default; do sleep 3; done
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
        until timeout 300 oc rollout status deployment.apps/default-cloud1-sens-meter-smartgateway; do sleep 3; done
    ;;

    "use_redhat")
        echo -e "\n* [info] Waiting for prometheus deployment to complete\n"
        until timeout 300 oc rollout status statefulset.apps/prometheus-default; do sleep 3; done
        echo -e "\n* [info] Waiting for alertmanager deployment to complete\n"
        until timeout 300 oc rollout status statefulset.apps/alertmanager-default; do sleep 3; done
        echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
        until timeout 300 oc rollout status deployment.apps/default-cloud1-coll-meter-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-ceil-meter-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-sens-meter-smartgateway; do sleep 3; done
    ;;

    "none")
        echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
        until timeout 300 oc rollout status deployment.apps/default-cloud1-coll-meter-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-ceil-meter-smartgateway; do sleep 3; done
        until timeout 300 oc rollout status deployment.apps/default-cloud1-sens-meter-smartgateway; do sleep 3; done
    ;;
esac

echo -e "\n* [info] Waiting for all pods to show Ready/Complete\n"
while oc get pods --selector '!openshift.io/build.name' | tail -n +2 | grep -v -E 'Running|Completed'; do
    sleep 3
done

# --- Operator health: RBAC denials and reconcile on existing objects ---------
# A green rollout only proves the first reconcile worked. RBAC gaps (e.g. a
# missing patch/list/watch verb) only show up when objects already exist, or
# as watch errors that never fail a task. Check both explicitly.

OPERATOR_SELECTOR="name=service-telemetry-operator"

operator_pod() {
    oc get pods -l "${OPERATOR_SELECTOR}" --field-selector=status.phase=Running \
        --sort-by=.metadata.creationTimestamp -o name | tail -1
}

# ansible-runner output has ANSI colour codes; strip them before matching
operator_log() {
    oc logs "$(operator_pod)" | sed -E 's/\x1b\[[0-9;]*m//g'
}

check_rbac_denials() {
    local denials
    denials=$(operator_log | grep -E 'is forbidden|Failed to watch' || true)
    if [ -n "${denials}" ]; then
        echo -e "\n* [error] Operator hit RBAC denials ($(wc -l <<< "${denials}") lines). First 20:\n"
        head -20 <<< "${denials}" | cut -c1-400
        exit 1
    fi
}

echo -e "\n* [info] Checking operator log for RBAC denials after initial deployment\n"
check_rbac_denials

echo -e "\n* [info] Restarting operator to force a reconcile against existing objects\n"
OLD_POD=$(operator_pod)
oc rollout restart deployment/service-telemetry-operator
oc rollout status deployment/service-telemetry-operator --timeout=300s
until [ -n "$(operator_pod)" ] && [ "$(operator_pod)" != "${OLD_POD}" ]; do sleep 3; done

echo -e "\n* [info] Waiting for the post-restart reconcile to finish\n"
until operator_log | grep -qE '^localhost +: ok=[0-9]+'; do sleep 10; done
RECAP=$(operator_log | grep -E '^localhost +: ok=[0-9]+' | head -1)
echo "${RECAP}"
if ! grep -qE 'failed=0( |$)' <<< "${RECAP}"; then
    echo -e "\n* [error] Reconcile after operator restart failed. Failed tasks:\n"
    operator_log | grep -oE '"EventData.Task":"[^"]*"|fatal: \[localhost\]: FAILED! => .{0,400}' | sort -u
    exit 1
fi

echo -e "\n* [info] Checking operator log for RBAC denials after restart reconcile\n"
check_rbac_denials

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
