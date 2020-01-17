#!/usr/bin/env bash
# File
#
# This file contains instruct command for local-docker script ld.sh.

function ld_command_instruct_exec() {

    COMMAND=$@
    FILE=./docker/scripts/ld.command.$COMMAND.sh
    if [[ -f "$FILE" ]]; then
        . $FILE
        FUNCTION="ld_command_"$COMMAND"_help"
        function_exists $FUNCTION && echo && echo -n "$COMMAND: $($FUNCTION)" && echo

        FUNCTION="ld_command_"$COMMAND"_extended_help"
        function_exists $FUNCTION && echo && echo -n "$($FUNCTION)" && echo && echo

    fi

}

function ld_command_instruct_help() {
    echo "Get extended instructions for a command."
}
