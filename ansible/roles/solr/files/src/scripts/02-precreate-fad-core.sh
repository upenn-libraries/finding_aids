#!/bin/bash
set -e

if [ ! -z "${CONFIG_LOCATION}" ] && [ ! -z "${CORE_NAME}" ]; then
    echo "Creating ${CORE_NAME}"
    precreate-core ${CORE_NAME} ${CONFIG_LOCATION}
fi
