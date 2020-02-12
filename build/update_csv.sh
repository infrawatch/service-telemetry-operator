#!/usr/bin/env bash
source "$(dirname "$0")/metadata.sh"

operator-sdk olm-catalog gen-csv --csv-version "${CSV_VERSION}" --operator-name service-telemetry-operator --update-crds
