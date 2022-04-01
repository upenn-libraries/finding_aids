#!/bin/bash
set -e

if [ ! -z "${CONFIG_LOCATION}" ] && [ ! -z "${CORE_NAME}" ] && [ -d "/var/solr/data/${CORE_NAME}/conf/" ]; then

    diff=""
    new_file=false

    # loop through the config files that were copied in and check if they are different when compared to the existing files
    # if we hit a new file or a file where there is a diff we can exit early and start the process of migrating/reloading data
    for file in "${CONFIG_LOCATION}/conf/*"; do
        # check if file exists
        if [ ! -f "/var/solr/data/${CORE_NAME}/conf/${file}" ]; then
            # a new file has been added - break early
            new_file=true
            break
        fi

        diff=$(diff "${CONFIG_LOCATION}/conf/${file}" "/var/solr/data/${CORE_NAME}/conf/${file}")

        # check if there is a diff between the copied and existing files
        if [ "${diff}" != "" ]; then
            break
        fi
    done

    # one or more config files is different than what exists in the container; take the necessary steps to migrate/reload data
    if [ "${diff}" != "" ] || [ "${new_file}" == true ]; then
        # if core exists then unload core, copy new files in, and prep for new core
        if curl "http://solr:8983/solr/admin/cores?action=STATUS" | grep "${CORE_NAME}"; then
            echo "Unload the original core"
            curl "http://solr:8983/solr/admin/cores?action=UNLOAD&core=${CORE_NAME}"

            echo "Waiting until write.lock and core.properties removed"
            until [[ ! -e "/var/solr/data/${CORE_NAME}/data/index/write.lock" ]] && [[ ! -e "/var/solr/data/${CORE_NAME}/core.properties" ]]; do
                echo "sleeping until write.lock and core.properties is removed..."
                sleep 1
            done

            echo "Copying the new config/s"
            cp -fr ${CONFIG_LOCATION}/conf/* /var/solr/data/${CORE_NAME}/conf/

            echo "Creating core.properties"
            touch "/var/solr/data/${CORE_NAME}/core.properties"
        fi
    fi
fi
