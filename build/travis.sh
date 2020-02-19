#!/bin/bash

# Fail on error
set -e

REL=$(dirname "$0")

# Add everything, get ready for commit. But only do it if we're on
# master. If you want to deploy on different branches, you can change
# this.
if [[ "$BRANCH" =~ ^master$|^[0-9]+\.[0-9]+\.X$ ]]; then
    echo "Branch is master, so push new application to Quay registry"
    export PATH=$HOME/bin:$PATH
    curl -L https://github.com/operator-framework/operator-sdk/releases/download/v0.12.0/operator-sdk-v0.12.0-x86_64-linux-gnu -o $HOME/bin/operator-sdk-v0.12.0
    chmod +x $HOME/bin/operator-sdk-v0.12.0
    operator-courier verify --ui_validate_io deploy/olm-catalog/service-telemetry-operator
    ansible-lint roles/servicetelemetry/
    ${REL}/update_csv.sh
    ${REL}/push_app2quay.sh
else
    echo "Not on master, so won't push new application artifacts"
fi
