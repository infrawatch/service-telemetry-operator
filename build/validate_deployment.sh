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
OPERATOR_POD_TIMEOUT="${OPERATOR_POD_TIMEOUT:-300}"
OPERATOR_RECONCILE_TIMEOUT="${OPERATOR_RECONCILE_TIMEOUT:-900}"
RECAP_REGEX='^localhost +: ok=[0-9]+'

# wait_for <timeout_seconds> <interval_seconds> <description> <command...>
# Re-runs the command until it succeeds; exits with a clear error on timeout.
wait_for() {
    local timeout="$1" interval="$2" description="$3"
    shift 3
    local deadline=$((SECONDS + timeout))
    until "$@"; do
        if [ "${SECONDS}" -ge "${deadline}" ]; then
            echo -e "\n* [error] Timed out after ${timeout}s waiting for: ${description}\n"
            return 1
        fi
        sleep "${interval}"
    done
}

operator_pod() {
    oc get pods -l "${OPERATOR_SELECTOR}" --field-selector=status.phase=Running \
        --sort-by=.metadata.creationTimestamp -o name | tail -1
}

# operator_log <pod>
# ansible-runner output has ANSI colour codes; strip them before matching
operator_log() {
    oc logs "$1" | sed -E 's/\x1b\[[0-9;]*m//g'
}

# check_operator_log <pod> <regex> <description>
check_operator_log() {
    local matches
    matches=$(operator_log "$1" | grep -E "$2" || true)
    if [ -n "${matches}" ]; then
        echo -e "\n* [error] Operator log has $3 ($(wc -l <<< "${matches}") lines). First 20:\n"
        head -20 <<< "${matches}" | cut -c1-400
        exit 1
    fi
}

new_operator_pod_ready() {
    local pod
    pod=$(operator_pod)
    [ -n "${pod}" ] && [ "${pod}" != "${OLD_POD}" ] && \
        oc wait "${pod}" --for=condition=Ready --timeout=10s >/dev/null 2>&1
}

reconcile_finished() {
    operator_log "${NEW_POD}" | grep -qE "${RECAP_REGEX}"
}

OLD_POD=$(operator_pod)
if [ -z "${OLD_POD}" ]; then
    echo -e "\n* [error] No running pod found for ${OPERATOR_SELECTOR}\n"
    exit 1
fi

# The first deployment can legitimately log reconcile retries while dependent
# services come up, so only RBAC denials fail the check here.
echo -e "\n* [info] Checking operator log for RBAC denials after initial deployment\n"
check_operator_log "${OLD_POD}" 'is forbidden|Failed to watch' "RBAC denials"

# Delete the pod rather than 'oc rollout restart': on OLM installs the
# deployment is owned by the CSV, and OLM may revert the restart annotation.
echo -e "\n* [info] Deleting ${OLD_POD} to force a reconcile against existing objects\n"
oc delete "${OLD_POD}" --wait=false
wait_for "${OPERATOR_POD_TIMEOUT}" 3 "a new Ready operator pod to replace ${OLD_POD}" new_operator_pod_ready
NEW_POD=$(operator_pod)
echo "* [info] New operator pod: ${NEW_POD}"

echo -e "\n* [info] Waiting for the post-restart reconcile to finish\n"
if ! wait_for "${OPERATOR_RECONCILE_TIMEOUT}" 10 "the reconcile recap in ${NEW_POD}" reconcile_finished; then
    echo "* [info] Last 50 lines of ${NEW_POD} log:"
    operator_log "${NEW_POD}" | tail -50 | cut -c1-400
    exit 1
fi
RECAP=$(operator_log "${NEW_POD}" | grep -E "${RECAP_REGEX}" | head -1)
echo "${RECAP}"
if ! grep -qE 'failed=0( |$)' <<< "${RECAP}"; then
    echo -e "\n* [error] Reconcile after operator restart failed. Failed tasks:\n"
    operator_log "${NEW_POD}" | grep -oE '"EventData.Task":"[^"]*"|fatal: \[localhost\]: FAILED! => .{0,400}' | sort -u
    exit 1
fi

# Every object already exists at this point, so any reconcile error is real.
echo -e "\n* [info] Checking operator log for RBAC denials and reconcile errors after restart\n"
check_operator_log "${NEW_POD}" 'is forbidden|Failed to watch|Reconciler error' "RBAC denials or reconcile errors"

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
