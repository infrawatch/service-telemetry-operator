#!/usr/bin/env bash
source "$(dirname "$0")/metadata.sh"

operator-sdk generate csv --csv-version "${CSV_VERSION}" --operator-name service-telemetry-operator --update-crds
