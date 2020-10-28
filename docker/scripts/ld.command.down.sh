#!/usr/bin/env bash
# File
#
# This file contains down -command for local-docker script ld.sh.

function ld_command_down_exec() {
    $SCRIPT_NAME db-dump
    CONN=$?
    if [ "$CONN" -ne "0" ]; then
        cd $CWD
        exit 1
    fi

    COMM=$(compose_command) " -f $DOCKER_COMPOSE_FILE down"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    $COMM

    if is_dockersync; then
        [ "$LD_VERBOSE" -ge "1" ] && echo 'Turning off docker-sync (clean), please wait...'
        docker-sync clean
    fi
    $SCRIPT_NAME configure-network-down
}

function ld_command_down_help() {
    echo "Generates a database backup and removes containers & networks (stops docker-sync)"
}
