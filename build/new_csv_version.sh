#!/usr/bin/env sh

if [ -z "$CSV_VERSION" ]; then
    echo -n "CSV version to create [e.g. 1.0.0-beta2]: "
    read CSV_VERSION
fi

if [ -z "$FROM_VERSION" ]; then
    echo -n "CSV version to upgrade from [e.g. 1.0.0-beta1]: "
    read FROM_VERSION
fi

if [ -z "$CSV_CHANNEL" ]; then
    echo -n "CSV channel to publish to [e.g. stable]: "
    read CSV_CHANNEL
fi


operator-sdk generate csv --csv-version=${CSV_VERSION} \
    --from-version=${FROM_VERSION}  \
    --operator-name service-telemetry-operator \
    --update-crds \
    --csv-channel="${CSV_CHANNEL}"
