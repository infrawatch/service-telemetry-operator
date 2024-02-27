#!/usr/bin/env bash
set -e
set -x

LOGFILE=${LOGFILE:-/dev/null}

# If LOGFILE is /dev/null, this command fails, so ignore that error
truncate --size=0 ${LOGFILE} || true

OPERATOR_SDK=${OPERATOR_SDK:-operator-sdk}

REL=$( readlink -f $(dirname "$0"))

# shellcheck source=build/metadata.sh
. "${REL}/metadata.sh"

generate_version() {
    UNIXDATE=$(date '+%s')
    OPERATOR_BUNDLE_VERSION=${OPERATOR_CSV_MAJOR_VERSION}.${UNIXDATE}
}

create_working_dir() {
    WORKING_DIR=${WORKING_DIR:-"/tmp/${OPERATOR_NAME}-bundle-${OPERATOR_BUNDLE_VERSION}"}
    mkdir -p "${WORKING_DIR}"
}

generate_dockerfile() {
    sed -E "s#<<OPERATOR_BUNDLE_VERSION>>#${OPERATOR_BUNDLE_VERSION}#g;s#<<BUNDLE_CHANNELS>>#${BUNDLE_CHANNELS}#g;s#<<BUNDLE_DEFAULT_CHANNEL>>#${BUNDLE_DEFAULT_CHANNEL}#g" "${REL}/../${BUNDLE_PATH}/Dockerfile.in" > "${WORKING_DIR}/Dockerfile"
}

generate_bundle() {
    REPLACE_REGEX="s#<<CREATED_DATE>>#${CREATED_DATE}#g;s#<<OPERATOR_IMAGE>>#${OPERATOR_IMAGE}#g;s#<<OPERATOR_TAG>>#${OPERATOR_TAG}#g;s#<<RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP>>#${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP}#g;s#<<RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_TAG>>#${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_TAG}#g;s#<<RELATED_IMAGE_OAUTH_PROXY>>#${RELATED_IMAGE_OAUTH_PROXY}#g;s#<<RELATED_IMAGE_OAUTH_PROXY_TAG>>#${RELATED_IMAGE_OAUTH_PROXY_TAG}#g;s#<<RELATED_IMAGE_PROMETHEUS>>#${RELATED_IMAGE_PROMETHEUS}#g;s#<<RELATED_IMAGE_PROMETHEUS_TAG>>#${RELATED_IMAGE_PROMETHEUS_TAG}#g;s#<<RELATED_IMAGE_ALERTMANAGER>>#${RELATED_IMAGE_ALERTMANAGER}#g;s#<<RELATED_IMAGE_ALERTMANAGER_TAG>>#${RELATED_IMAGE_ALERTMANAGER_TAG}#g;s#<<OPERATOR_BUNDLE_VERSION>>#${OPERATOR_BUNDLE_VERSION}#g;s#1.99.0#${OPERATOR_BUNDLE_VERSION}#g;s#<<OPERATOR_DOCUMENTATION_URL>>#${OPERATOR_DOCUMENTATION_URL}#g;s#<<BUNDLE_OLM_SKIP_RANGE_LOWER_BOUND>>#${BUNDLE_OLM_SKIP_RANGE_LOWER_BOUND}#g"

    pushd "${REL}/../" > /dev/null 2>&1
    ${OPERATOR_SDK} generate bundle --verbose --channels ${BUNDLE_CHANNELS} --default-channel ${BUNDLE_DEFAULT_CHANNEL} --manifests --metadata --version "${OPERATOR_BUNDLE_VERSION}" --output-dir "${WORKING_DIR}" >> ${LOGFILE} 2>&1
    popd > /dev/null 2>&1

    # CSVs without a spec.replaces field are valid, so fall back to those if
    # latest released version is unknown.
    # Placeholder value is validated by operator-sdk during local bundle
    # generation and so needs to conform to RFC1123.
    if [[ -n "$BUNDLE_LATEST_RELEASED_VERSION" ]]; then
        REPLACE_REGEX="$REPLACE_REGEX;s#---bundle-latest-released-version#${BUNDLE_LATEST_RELEASED_VERSION}#g"
    else sed -i '/---bundle-latest-released-version/d' "${WORKING_DIR}/manifests/${OPERATOR_NAME}.clusterserviceversion.yaml"
    fi

    sed -i -E "${REPLACE_REGEX}" "${WORKING_DIR}/manifests/${OPERATOR_NAME}.clusterserviceversion.yaml"
}

copy_extra_metadata() {
    # We add this because our version of operator-sdk for building doesn't
    # understand these files, but newer versions of operator-sdk (for testing
    # purposes) does, and newer versions of opm (as used in both downstream and
    # upstream index image builds) also understands these files. Just copy them
    # into the bundle directory during building.
    pushd "${REL}/../" > /dev/null 2>&1
    cp -r ./deploy/olm-catalog/service-telemetry-operator/tests/ "${WORKING_DIR}"
    cp ./deploy/olm-catalog/service-telemetry-operator/metadata/properties.yaml "${WORKING_DIR}/metadata/"
}

build_bundle_instructions() {
    echo "-- Commands to create a bundle build"
    echo docker build -t "${OPERATOR_BUNDLE_IMAGE}:${OPERATOR_BUNDLE_VERSION}" -f "${WORKING_DIR}/Dockerfile" "${WORKING_DIR}"
    echo docker push ${OPERATOR_BUNDLE_IMAGE}:${OPERATOR_BUNDLE_VERSION}
}


# generate templates
#echo "## Begin bundle creation"
generate_version
create_working_dir
generate_dockerfile
generate_bundle
copy_extra_metadata
#build_bundle_instructions
#echo "## End Bundle creation"

set +x
JSON_OUTPUT='{"operator_bundle_image":"%s","operator_bundle_version":"%s","operator_image":"%s","bundle_channels":"%s","bundle_default_channel":"%s","operator_tag":"%s","working_dir":"%s"}'
printf "$JSON_OUTPUT" "$OPERATOR_BUNDLE_IMAGE" "$OPERATOR_BUNDLE_VERSION" "$OPERATOR_IMAGE" "$BUNDLE_CHANNELS" "$BUNDLE_DEFAULT_CHANNEL" "$OPERATOR_TAG" "$WORKING_DIR"
