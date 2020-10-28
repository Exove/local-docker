#!/usr/bin/env bash
# File
#
# This file contains up -command for local-docker script ld.sh.

function ld_command_up_exec() {

    $SCRIPT_NAME configure-network

    COMMAND_SQL_DB_RESTORE_INFO="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -e 'show databases'"
    COMMAND_SQL_DB_USERS="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -D mysql -e \"SELECT User, Host from mysql.user WHERE User NOT LIKE 'mysql%';\""

    if is_dockersync; then
        [ "$LD_VERBOSE" -ge "1" ] && echo "Starting docker-sync, please wait..."
        docker-sync start
    fi
    ensure_folders_present ${DATABASE_DUMP_STORAGE:-db_dumps}
    $(compose_command) -f $DOCKER_COMPOSE_FILE up -d
    $SCRIPT_NAME drupal-files-folder-perms
    OK=$?
    if [ "$OK" -ne "0" ]; then
        echo
        echo -e "${Red}ERROR: Something went wrong when bringing the project up.${Color_Off}"
        echo -e "${Red}Check that required ports are not allocated (by other containers or programs) and re-configure them if needed.${Color_Off}"
        cd $CWD
        exit 1
    fi

    db_connect
    RET="$?"
    case "$RET" in
      1|"1")
        echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
        return $RET
        ;;

      2|"2")
        echo -e "${Red}ERROR: Some other and undetected issue when connecting DB container.${Color_Off}"
        return $RET
        ;;

      3|"3")
       echo -e "${Red}ERROR: DB container not running (or not yet created).${Color_Off}"
       return $RET
       ;;
    esac

    echo
    if [ "$LD_VERBOSE" -ge "1" ]; then
        echo -e "${Yellow}Current databases:${Color_Off}"
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORE_INFO 2>/dev/null"
        echo -e "${Yellow}Current database users:${Color_Off}"
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_USERS 2>/dev/null"
        echo -e "${Yellow}NOTE: No database dump restored.${Color_Off}"
        echo 'In case you need to do that (Drupal DB is gone?), run command'
        echo '$ '$SCRIPT_NAME_SHORT db-import [drupal]
        echo 'Optionally you may also restore from full DB container backup using command'
        echo '$ '$SCRIPT_NAME_SHORT db-restore [db_dumps/db-container--FULL--LATEST.sql.gz]
    fi
}

function ld_command_up_help() {
    echo "Brings containers up with building step if necessary (starts docker-sync)"
}
