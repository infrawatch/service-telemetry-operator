#!/usr/bin/env bash
#
# Entrypoint to build and deploy for CI
#
set -e
REL=$(dirname "$0"); source "${REL}/metadata.sh"

echo "Building..."
"${REL}/build.sh"

echo "Removing old SAF..."
"${REL}/../deploy/remove_saf.sh"

# Running quickstart triggers an initial install via a subscription.
# OLM satisfies dependencies via the subscription, allowing us to test our deps
# are still working as well as creating a more DRY CI deployment.
# We pass "nosaf" config which supresses the creation of the ServiceAssurance
# object itself, effectively preventing the original operator from doing
# "anything" (except establishing the CRD.... and...?)
echo "Running quickstart..."
SAF_CONFIG="configs/nosaf.bash" "${REL}/../deploy/quickstart.sh"

echo "Pushing new operator image..."
"${REL}/push_container2ocp.sh"

# After quickstart, a CSV pointing at the upstream SAO image will be installed.
# This script removes it and replaces it with the patched version
echo "Re-deploying with local build..."
"${REL}/deploy_local_build.sh"

# Now we can install an SAF object for the locally built operator to work on
source "${REL}/../deploy/configs/default.bash"
oc create -f - <<< "${KIND_SERVICEASSURANCE}"