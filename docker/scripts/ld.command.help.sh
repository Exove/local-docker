#!/usr/bin/env bash
# File
#
# This file contains the help command for local-docker script ld.sh.

function ld_command_help_exec() {
    SINGLE_COMMAND=$1

    if [ -n "$SINGLE_COMMAND" ]; then
        ld_command_extended_help_exec $SINGLE_COMMAND
    else
        ld_command_general_help_exec
    fi
}

function ld_command_general_help_exec() {

    echo "Local-docker, version $LOCAL_DOCKER_VERSION"
    echo
    echo "This is a simple script, aimed to help in developer's daily use of local environment."
    echo "While local-docker is mainly targeted for Drupal, it works with any Composer managed codebase."
    echo "If you have docker-sync installed and configuration present (docker-sync.yml) it controls that too."
    echo
    echo 'Usage:'
    echo "$SCRIPT_NAME_SHORT [command]"
    echo
    echo "Available commands:"

    # Loop through all commands printing whatever they explain to be doing.
    for COMMAND in ${COMMANDS[@]}; do
      FILE=./docker/scripts/ld.command.$COMMAND.sh
      if [[ -f "$FILE" ]]; then
          . $FILE
          FUNCTION="ld_command_"$COMMAND"_help"
          function_exists $FUNCTION && echo -e "  - ${BGreen}$COMMAND${Color_Off}: $($FUNCTION)"

      fi
    done

}

function ld_command_extended_help_exec() {

    COMMAND=$1
    FILE=./docker/scripts/ld.command.$COMMAND.sh
    if [[ -f "$FILE" ]]; then
        . $FILE
        FUNCTION="ld_command_"$COMMAND"_help"
        function_exists $FUNCTION && echo && echo -e "${BGreen}$COMMAND${Color_Off}: $($FUNCTION)" && echo

        FUNCTION="ld_command_"$COMMAND"_extended_help"
        if function_exists $FUNCTION; then
            STRINGS=$($FUNCTION)
            #Set the field separator to new line
            OIFS="$IFS"
            IFS=$'\n'

            for LINE in $STRINGS; do
                echo "    $LINE"
            done
            IFS="$OIFS"
        else
            echo "    No extended help for ${COMMAND} available."
        fi
        echo
    fi

}
