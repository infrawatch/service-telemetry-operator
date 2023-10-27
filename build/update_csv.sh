#!/usr/bin/env bash

# Run this script from the root directory to update the CSV whenever changes
# are made to /deploy/crds/. Changes are written to
# /deploy/olm-manifests/service-telemetry-operator/.
operator-sdk generate bundle --channels stable-1.5 --default-channel stable-1.5
