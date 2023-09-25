# Config location
ARG CONFIG_LOCATION=/finding_aid_discovery_configs

# Core name
ARG CORE_NAME=finding-aid-discovery-core

# Image name
ARG IMAGE_NAME=solr

# Image tag
ARG IMAGE_TAG=9.2.1


FROM ${IMAGE_NAME}:${IMAGE_TAG}

ARG CONFIG_LOCATION
ENV CONFIG_LOCATION=${CONFIG_LOCATION}

ARG CORE_NAME
ENV CORE_NAME=${CORE_NAME}

USER root

COPY conf/ ${CONFIG_LOCATION}/conf/
COPY scripts/ /docker-entrypoint-initdb.d/

USER $SOLR_USER
