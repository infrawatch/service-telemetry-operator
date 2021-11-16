#!/usr/bin/env bash

# Run this script from the root directory to update the CSV whenever changes
# are made to /deploy/crds/. Changes are written to
# /deploy/olm-manifests/service-telemetry-operator/.
operator-sdk generate bundle --channels unstable --default-channel unstable
