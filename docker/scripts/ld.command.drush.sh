#!/usr/bin/env bash
# File
#
# This file contains drush -command for local-docker script ld.sh.

function ld_command_drush_exec() {
    CONT_ID=$(find_container ${CONTAINER_PHP:-php})
    if [ "$?" -eq "1" ]; then
      echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
      return 1
    fi
    if [ -z "$CONT_ID" ]; then
      echo -e "${Red}ERROR: PHP container ('${CONTAINER_PHP:-php}')is not up.${Color_Off}"
      return 2
    fi
    COMM=$(compose_command) " exec -T ${CONTAINER_PHP:-php} /var/www/vendor/drush/drush/drush $@"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    $COMM
}

function ld_command_drush_help() {
    echo "Run drush command in PHP container (if up and running)"
}
