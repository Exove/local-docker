#!/usr/bin/env bash
# File
#
# This file contains drupal-structure-fix -command for local-docker script ld.sh.

function ld_command_drupal-structure-fix_exec() {
    CONT_ID=$(find_container ${CONTAINER_PHP:-php})
    if [ "$?" -eq "1" ]; then
      echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
      return 1
    fi
    if [ -z "$CONT_ID" ]; then
      echo -e "${Red}ERROR: PHP container ('${CONTAINER_PHP:-php}') is not up.${Color_Off}"
      return 2
    fi
    [ "$LD_VERBOSE" -ge "1" ] && echo -e "${Yellow}Creating some folders and setting file perms to project below ${BYellow}${APP_ROOT}${Yellow}.${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c '[[ ! -d "config/sync" ]] &&  mkdir -vp config/sync'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c '[[ ! -d "web/sites/default/files" ]] &&  mkdir -vp web/sites/default/files'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c '[[ ! -w "web/sites/default/files" ]] &&  chmod -r 0777 web/sites/default/files'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'if [ $(su -s /bin/sh www-data -c "test -w \"web/sites/default/files\"") ]; then echo "web/sites/default/files is writable - GREAT!"; else chmod -v a+wx web/sites/default/files; fi'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'if [ $(su -s /bin/sh www-data -c "test -w \"web/sites/default/settings.php\"") ]; then echo "web/sites/default/settings.php is writable - GREAT!"; else chmod -v a+w web/sites/default/settings.php; fi'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'mkdir -vp ./web/modules/custom && mkdir -vp ./web/themes/custom'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'echo > ./web/modules/custom/.gitkeep'
    docker-compose -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_PHP:-php} bash -c 'echo > ./web/themes/custom/.gitkeep'
}

function ld_command_drupal-structure-fix_help() {
    echo "Tries to fix ownership and file perms issues inside PHP container."
}

