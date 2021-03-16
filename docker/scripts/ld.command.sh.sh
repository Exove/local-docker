#!/usr/bin/env bash
# File
#
# This file contains sh -command for local-docker script ld.sh.

function ld_command_sh_exec() {
    if [ -z "$@" ]; then
        echo -e "${Cyan}No argument provided: assuming you want to shell into php container${Color_Off}"
        if [ -z "$CONTAINER_PHP" ]; then
            echo -e "${Red}ERROR: PHP container name is missing.${Color_Off}"
            echo -e "${Red}Ensure you have variable 'CONTAINER_PHP' set in configuration.${Color_Off}"
            exit 1
        fi
        CONTAINER=$CONTAINER_PHP
    else
        CONTAINER=$@
    fi
    
    CONT_ID=$(find_container $CONTAINER)
    if [ -z "$CONT_ID" ]; then
        echo -e "${Red}ERROR: The requested container is not up.${Color_Off}"
        exit 1
    fi
    COMM="docker-compose exec ${CONTAINER} sh"
    echo -e "${Cyan}Next: $COMM${Color_Off}"
    $COMM
}

function ld_command_sh_help() {
    echo "Open the shell in a container (if up and running)."
    echo "If no container id specified, the php one will be used."
}
