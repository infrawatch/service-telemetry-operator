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
# as list/watch denials that never fail a task. Check both explicitly.

OPERATOR_SELECTOR="name=service-telemetry-operator"
OPERATOR_POD_TIMEOUT="${OPERATOR_POD_TIMEOUT:-300}"
OPERATOR_RECONCILE_TIMEOUT="${OPERATOR_RECONCILE_TIMEOUT:-900}"
# Total budget the caller gives this script (see stf-run-ci); if set, the
# reconcile wait is capped so we fail with a diagnostic before the outer
# timeout kills us. Unset (e.g. when run by hand) means no cap.
VALIDATION_TIMEOUT="${VALIDATION_TIMEOUT:-}"
# Optional directory to save the pre-restart operator log into (CI artifacts).
LOGFILE_DIR="${LOGFILE_DIR:-}"
RECAP_REGEX='^localhost +: ok=[0-9]+'
# Matches both API denials ("... is forbidden: User ... cannot patch ...") and
# list/watch denials logged by client-go informers.
RBAC_REGEX='is forbidden'

# wait_for <timeout_seconds> <interval_seconds> <description> <command...>
# Re-runs the command until it succeeds; returns 1 with a clear error on timeout.
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

# fetch_operator_log <pod>
# Prints the pod log with ANSI colour codes (from ansible-runner) stripped.
# Exits the script if the log can't be read, so a failed 'oc logs' is never
# mistaken for a clean log.
fetch_operator_log() {
    local raw
    if ! raw=$(oc logs "$1"); then
        echo -e "\n* [error] Could not read the log of $1\n" >&2
        exit 1
    fi
    sed -E $'s/\x1b\\[[0-9;]*m//g' <<< "${raw}"
}

# check_log <log> <regex> <description>
check_log() {
    local matches
    matches=$(grep -E "$2" <<< "$1" || true)
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
    oc logs "${NEW_POD}" 2>/dev/null | sed -E $'s/\x1b\\[[0-9;]*m//g' | grep -qE "${RECAP_REGEX}"
}

OLD_POD=$(operator_pod)
if [ -z "${OLD_POD}" ]; then
    echo -e "\n* [error] No running pod found for ${OPERATOR_SELECTOR}\n"
    exit 1
fi

OLD_LOG=$(fetch_operator_log "${OLD_POD}")
# The pod is deleted below, so keep its log (the initial deployment reconcile)
# for the CI artifacts; post-run log collection only sees the current pod.
if [ -n "${LOGFILE_DIR}" ]; then
    printf '%s\n' "${OLD_LOG}" > "${LOGFILE_DIR}/logs_sto_initial.log"
fi

# The first deployment can legitimately log reconcile retries while dependent
# services come up, so only RBAC denials fail the check here.
echo -e "\n* [info] Checking operator log for RBAC denials after initial deployment\n"
check_log "${OLD_LOG}" "${RBAC_REGEX}" "RBAC denials"

# Delete the pod rather than 'oc rollout restart': on OLM installs the
# deployment is owned by the CSV, and OLM may revert the restart annotation.
# The ReplicaSet starts the replacement as soon as the old pod is marked for
# deletion, so the two may briefly overlap during the old pod's grace period.
echo -e "\n* [info] Deleting ${OLD_POD} to force a reconcile against existing objects\n"
oc delete "${OLD_POD}" --wait=false
wait_for "${OPERATOR_POD_TIMEOUT}" 3 "a new Ready operator pod to replace ${OLD_POD}" new_operator_pod_ready
NEW_POD=$(operator_pod)
echo "* [info] New operator pod: ${NEW_POD}"

if [ -n "${VALIDATION_TIMEOUT}" ]; then
    # Leave 60s of the caller's budget for reporting.
    RECONCILE_BUDGET=$((VALIDATION_TIMEOUT - SECONDS - 60))
    if [ "${RECONCILE_BUDGET}" -le 0 ]; then
        echo -e "\n* [error] Validation budget (${VALIDATION_TIMEOUT}s) exhausted before the post-restart reconcile check\n"
        exit 1
    fi
    if [ "${RECONCILE_BUDGET}" -lt "${OPERATOR_RECONCILE_TIMEOUT}" ]; then
        echo "* [info] Capping reconcile wait to ${RECONCILE_BUDGET}s (remaining validation budget)"
        OPERATOR_RECONCILE_TIMEOUT="${RECONCILE_BUDGET}"
    fi
fi

echo -e "\n* [info] Waiting for the post-restart reconcile to finish\n"
if ! wait_for "${OPERATOR_RECONCILE_TIMEOUT}" 10 "the reconcile recap in ${NEW_POD}" reconcile_finished; then
    echo "* [info] Last 50 lines of ${NEW_POD} log:"
    fetch_operator_log "${NEW_POD}" | tail -50 | cut -c1-400
    exit 1
fi

NEW_LOG=$(fetch_operator_log "${NEW_POD}")
RECAP=$(grep -E "${RECAP_REGEX}" <<< "${NEW_LOG}" | head -1)
if [ -z "${RECAP}" ]; then
    echo -e "\n* [error] Recap line disappeared from the ${NEW_POD} log\n"
    exit 1
fi
echo "${RECAP}"
if ! grep -qE 'failed=0( |$)' <<< "${RECAP}"; then
    echo -e "\n* [error] Reconcile after operator restart failed. Failed tasks:\n"
    grep -oE '"EventData.Task":"[^"]*"|fatal: \[localhost\]: FAILED! => .{0,400}' <<< "${NEW_LOG}" | sort -u
    exit 1
fi

# Every object already exists at this point, so any reconcile error is real.
echo -e "\n* [info] Checking operator log for RBAC denials and reconcile errors after restart\n"
check_log "${NEW_LOG}" "${RBAC_REGEX}|Reconciler error" "RBAC denials or reconcile errors"

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
