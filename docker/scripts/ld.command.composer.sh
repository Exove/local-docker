#!/usr/bin/env bash
# File
#
# This file contains composer -command for local-docker script ld.sh.

function ld_command_composer_exec() {
    CONT_ID=$(find_container ${CONTAINER_PHP:-php})
    if [ "$?" -eq "1" ]; then
      echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
      return 1
    fi
    if [ -z "$CONT_ID" ]; then
      echo -e "${Red}ERROR: PHP container ('${CONTAINER_PHP:-php}')is not up.${Color_Off}"
      return 2
    fi

    COMM=$(compose_command) " exec -T ${CONTAINER_PHP:-php} /usr/local/bin/composer -vv $@"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    $COMM
}

function ld_command_composer_help() {
    echo "Run composer command in PHP container (if up and running)"
}
