#!/usr/bin/env bash
# File
#
# This file contains solr-config-update -command for local-docker script ld.sh.

function ld_command_solr-config-update_exec() {

    COMM="docker-compose exec ${CONTAINER_SOLR:-solr} bash -c \"cp /solr-config/conf/* /var/solr/data/${SOLR_CORE}/conf\""
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    $COMM

    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: Restarting Solr container, please wait...${Color_Off}"
    docker-compose restart ${CONTAINER_SOLR:-solr}
}

function ld_command_solr-config-update_help() {
    echo "Copies fresh configuration files into the solr container and restarts solr container"
}
