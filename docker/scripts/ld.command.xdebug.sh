#!/usr/bin/env bash
# File
#
# This file contains stop -command for local-docker script ld.sh.

function ld_command_xdebug_exec() {
    # NOTE we push these values to developer's local ENV file .env.local to
    # avoid repeated changes known by Git in the project level file.
    case "$1" in
        '1'|'on') define_configuration_value PHP_XDEBUG_REMOTE_ENABLE 1 .env.local; sleep 1; $(compose_command) -f $DOCKER_COMPOSE_FILE up -d php && $SCRIPT_NAME xdebug;;
        '0'|'off') define_configuration_value PHP_XDEBUG_REMOTE_ENABLE 0 .env.local; $(compose_command) -f $DOCKER_COMPOSE_FILE up -d php && $SCRIPT_NAME xdebug;;
        *) $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T php bash -c 'echo -n "Xdebug is: "; php -i | grep xdebug.remote_enable |tr -s " => " "|" | cut -d "|" -f2';;
    esac

}

function ld_command_xdebug_help() {
    echo "Set or get Xdebug status (enabled, disabled). Optional paremeter to toggle value ['on'|1|'off'|0], omit to get current value."
}
