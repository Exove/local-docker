#!/usr/bin/env bash
# File
#
# This file contains phpcs command for local-docker script ld.sh.

function ld_command_phpcs_exec() {
    CONT_ID=$(find_container ${CONTAINER_PHP:-php})
    if [ "$?" -eq "1" ]; then
      echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
      return 1
    fi
    if [ -z "$CONT_ID" ]; then
      echo -e "${Red}ERROR: PHP container ('${CONTAINER_PHP:-php}') is not up.${Color_Off}"
      return 2
    fi
    COMM="docker-compose exec -T ${CONTAINER_PHP:-php} /var/www/vendor/bin/phpcs $@"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
    $COMM
}

function ld_command_phpcs_help() {
    echo "Run phpcs command in PHP container (if up and running)."
}

function ld_command_phpcs_extended_help() {
    echo "Drupal and DrupalPractice coding standards will be supported as long as"
    echo "dealerdirect/phpcodesniffer-composer-installer package has been installed."
    echo "To target e.g. your custom modules, use /var/www/web/modules/custom as the argument."
    echo
    echo "Example: $SCRIPT_NAME_SHORT phpcs --extensions=module,theme,php,inc --standard=Drupal,DrupalPractice /var/www/web/modules/custom"
}
