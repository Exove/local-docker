#!/usr/bin/env bash
# File
#
# This file contains solr-config-update -command for local-docker script ld.sh.

function ld_command_solr-config-update_exec() {
    docker-compose exec ${CONTAINER_SOLR:-solr} bash -c "cp /solr-config/conf/* /var/solr/data/${SOLR_CORE}/conf"
    docker-compose restart ${CONTAINER_SOLR:-solr}
}

function ld_command_solr-config-update_help() {
    echo "Copies fresh configuration files into the solr container and restarts solr container"
}
