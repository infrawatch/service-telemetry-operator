#!/bin/bash

# Fail on error
set -e
REL=$(dirname "$0")

echo "Pushing new application to Quay registry"
export PATH=$HOME/bin:$PATH
curl -L https://github.com/operator-framework/operator-sdk/releases/download/v0.15.2/operator-sdk-v0.15.2-x86_64-linux-gnu -o "$HOME/bin/operator-sdk"
chmod +x "$HOME/bin/operator-sdk"

# Push new application version, but strip the first character which is expected to be 'v'
# Why not just create tags that don't have 'v'? Because the container image versions are expected to lead with a 'v'. Fun!
CSV_VERSION="${TRAVIS_TAG:1}" "${REL}/../push_app2quay.sh"
