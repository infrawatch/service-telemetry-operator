#!/usr/bin/env bash
#
# Entrypoint to build and deploy for CI
#
set -e
REL=$(dirname "$0"); source "${REL}/metadata.sh"

echo -e "\n* [info] Building...\n"
"${REL}/build.sh"

echo -e "\n* [info] Removing old SAF...\n"
"${REL}/../deploy/remove_saf.sh"

# Running quickstart triggers an initial install via a subscription.
# OLM satisfies dependencies via the subscription, allowing us to test our deps
# are still working as well as creating a more DRY CI deployment.
# We pass "nosaf" config which supresses the creation of the ServiceAssurance
# object itself, effectively preventing the original operator from doing
# "anything" (except establishing the CRD.... and...?)
echo -e "\n* [info] Running quickstart...\n"
SAF_CONFIG="configs/nosaf.bash" "${REL}/../deploy/quickstart.sh"

echo -e "\n* [info] Pushing new operator image...\n"
"${REL}/push_container2ocp.sh"

# After quickstart, a CSV pointing at the upstream SAO image will be installed.
# This script removes it and replaces it with the patched version
echo -e "\n* [info] Re-deploying with local build...\n"
"${REL}/deploy_local_build.sh"

# Now we can install an SAF object for the locally built operator to work on
source "${REL}/../deploy/configs/default.bash"
oc create -f - <<< "${KIND_SERVICEASSURANCE}"

# Play the (automated!) waiting game
echo -e "\n* [info] Waiting for QDR deployment to complete\n"
until timeout 300 oc rollout status deployment.apps/saf-default-interconnect; do sleep 3; done
echo -e "\n* [info] Waiting for prometheus deployment to complete\n"
until timeout 300 oc rollout status statefulset.apps/prometheus-saf-default; do sleep 3; done
echo -e "\n* [info] Waiting for alertmanager deployment to complete\n"
until timeout 300 oc rollout status statefulset.apps/alertmanager-saf-default; do sleep 3; done
echo -e "\n* [info] Waiting for smart-gateway deployment to complete\n"
until timeout 300 oc rollout status deploymentconfig.apps.openshift.io/saf-default-telemetry-smartgateway; do sleep 3; done
echo -e "\n* [info] Waiting for all pods to show Ready/Complete\n"
while oc get pods | tail -n +2 | grep -v -E 'Running|Completed'; do
    sleep 3
done

echo -e "\n* [info] CI Build complete. You can now run tests.\n"
