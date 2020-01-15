#!/usr/bin/env sh
CSV_VERSION=${CSV_VERSION:-0.1.1}
operator-sdk olm-catalog gen-csv --csv-version ${CSV_VERSION} --operator-name service-assurance-operator --update-crds
