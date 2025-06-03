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
    # FOR COMPATIBILITY -- can be removed once all our builds and CI set _PULLSPEC vars
    # If we get separate $FOO and $FOO_TAG, combine them to set $FOO_PULLSPEC
    images=(
        OPERATOR_IMAGE
        RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP
        RELATED_IMAGE_OAUTH_PROXY
        RELATED_IMAGE_PROMETHEUS
        RELATED_IMAGE_ALERTMANAGER
    )

    for image_var in "${images[@]}"; do
        tag_var="${image_var}_TAG"
        image_value="${!image_var}"
        tag_value="${!tag_var}"

        if [[ -n "$image_value" && -n "$tag_value" ]]; then
            declare "${image_var}_PULLSPEC"="${image_value}:${tag_value}"
        fi
    done

    REPLACE_REGEX="s#<<CREATED_DATE>>#${CREATED_DATE}#g;s#<<OPERATOR_IMAGE_PULLSPEC>>#${OPERATOR_IMAGE_PULLSPEC}#g;s#<<RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_PULLSPEC>>#${RELATED_IMAGE_PROMETHEUS_WEBHOOK_SNMP_PULLSPEC}#g;s#<<RELATED_IMAGE_OAUTH_PROXY_PULLSPEC>>#${RELATED_IMAGE_OAUTH_PROXY_PULLSPEC}#g;s#<<RELATED_IMAGE_PROMETHEUS_PULLSPEC>>#${RELATED_IMAGE_PROMETHEUS_PULLSPEC}#g;s#<<RELATED_IMAGE_ALERTMANAGER_PULLSPEC>>#${RELATED_IMAGE_ALERTMANAGER_PULLSPEC}#g;s#<<OPERATOR_BUNDLE_VERSION>>#${OPERATOR_BUNDLE_VERSION}#g;s#1.99.0#${OPERATOR_BUNDLE_VERSION}#g;s#<<OPERATOR_DOCUMENTATION_URL>>#${OPERATOR_DOCUMENTATION_URL}#g"

    pushd "${REL}/../" > /dev/null 2>&1
    ${OPERATOR_SDK} generate bundle --verbose --package ${OPERATOR_NAME} --input-dir deploy --channels ${BUNDLE_CHANNELS} --default-channel ${BUNDLE_DEFAULT_CHANNEL} --manifests --metadata --version "${OPERATOR_BUNDLE_VERSION}" --output-dir "${WORKING_DIR}" >> ${LOGFILE} 2>&1 0<&-
    popd > /dev/null 2>&1
    # Hacks to generate the same bundle using v1.39.2 operator-sdk as we got using v0.19.4.
    # Can be removed if we ever adapt to latest operator-sdk project dir expectations.
    rm -f "${WORKING_DIR}/manifests/prometheus-alarm-rules_monitoring.rhobs_v1_prometheusrule.yaml"

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
JSON_OUTPUT='{"operator_bundle_image":"%s","operator_bundle_version":"%s","operator_image_pullspec":"%s","bundle_channels":"%s","bundle_default_channel":"%s","working_dir":"%s"}'
printf "$JSON_OUTPUT" "$OPERATOR_BUNDLE_IMAGE" "$OPERATOR_BUNDLE_VERSION" "$OPERATOR_IMAGE_PULLSPEC" "$BUNDLE_CHANNELS" "$BUNDLE_DEFAULT_CHANNEL" "$WORKING_DIR"
