#!/usr/bin/env bash
#
# Entrypoint to build and deploy for CI
#
set -e
REL=$(dirname "$0"); source "${REL}/../build/metadata.sh"

# Running quickstart triggers an initial install via a subscription.
# OLM satisfies dependencies via the subscription, allowing us to test our deps
# are still working as well as creating a more DRY CI deployment.
# We pass "nostf" config which supresses the creation of the ServiceTelemetry
# object itself, effectively preventing the original operator from doing
# "anything" (except establishing the CRD.... and...?)
echo -e "\n* [info] Running quickstart...\n"
QUICKSTART_CONFIG="configs/nostf.bash" "${REL}/quickstart.sh"

# After quickstart, a CSV pointing at the upstream SAO image will be installed.
# This script removes it and replaces it with the patched version
echo -e "\n* [info] Re-deploying with local build...\n"
"${REL}/deploy_local_build.sh"

# Now we can install an STF object for the locally built operator to work on
source "${REL}/${QUICKSTART_CONFIG}"
oc create -f - <<< "${KIND_SERVICETELEMETRY}"

# Play the (automated!) waiting game
echo -e "\n* [info] Waiting for QDR deployment to complete\n"
until timeout 300 oc rollout status deployment.apps/stf-default-interconnect; do sleep 3; done
echo -e "\n* [info] Waiting for prometheus deployment to complete\n"
until timeout 300 oc rollout status statefulset.apps/prometheus-stf-default; do sleep 3; done
echo -e "\n* [info] Waiting for elasticsearch deployment to complete \n"
while true; do
    ES_READY=$(oc get statefulsets elasticsearch-es-default -ogo-template='{{ .status.readyReplicas }}') || continue
    if [ "${ES_READY}" == "1" ]; then
        break
    fi
    sleep 3
done
echo -e "\n* [info] Waiting for alertmanager deployment to complete\n"
until timeout 300 oc rollout status statefulset.apps/alertmanager-stf-default; do sleep 3; done
echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
until timeout 300 oc rollout status deployment.apps/stf-default-collectd-telemetry-smartgateway; do sleep 3; done
until timeout 300 oc rollout status deployment.apps/stf-default-collectd-notification-smartgateway; do sleep 3; done
until timeout 300 oc rollout status deployment.apps/stf-default-ceilometer-notification-smartgateway; do sleep 3; done
echo -e "\n* [info] Waiting for all pods to show Ready/Complete\n"
while oc get pods | tail -n +2 | grep -v -E 'Running|Completed'; do
    sleep 3
done

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
