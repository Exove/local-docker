#!/usr/bin/env bash
# File
#
# This file contains drupal-files-folder-perms -command for local-docker script ld.sh.

function ld_command_drupal-files-folder-perms_exec() {
    CONT_ID=$(find_container ${CONTAINER_PHP:-php})
    if [ "$?" -eq "1" ]; then
      echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
      return 1
    fi
    if [ -z "$CONT_ID" ]; then
        echo -e "${Red}ERROR: PHP container ('${CONTAINER_PHP:-php}') is not up.${Color_Off}"
        return 2
    fi

    # Set folder perms, only, for speed.
    COMM="docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'find /var/www/web/sites -type d -exec chown -R www-data {}'"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c "chown -R www-data:root /var/www/web/sites"

    # Set topmost file perms, only, for speed.
    COMM="docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'find web/sites/ -maxdepth 2 -type f -exec chown -R www-data {}'"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c "chown -R www-data:root /var/www/web/sites"
}

function ld_command_drupal-files-folder-perms_help() {
    echo "Tries to ensure all Drupal sites files -dirs are writable inside php container."
}
