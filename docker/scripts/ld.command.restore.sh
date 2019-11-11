#!/usr/bin/env bash
# File
#
# This file contains restore -command for local-docker script ld.sh.

function ld_command_restore_exec() {
    TARGET_FILE_NAME=${1:-${DATABASE_DUMP_STORAGE}/db-container-dump-LATEST.sql.gz}
    COMMAND_SQL_DB_RESTORE_INFO="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -e 'show databases'"
    COMMAND_SQL_DB_RESTORER="gunzip < /var/db_dumps/db-container-dump-LATEST.sql.gz | mysql --host "${CONTAINER_DB:-db}" -uroot -p"$MYSQL_ROOT_PASSWORD""
    COMMAND_SQL_DB_USERS="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -D mysql -e \"SELECT User, Host from mysql.user WHERE User NOT LIKE 'mysql%';\""

    if [ ! -e "$TARGET_FILE_NAME" ]; then
        if [ -z "$1" ]; then
            echo -e "${Red}"
            echo "********************************************************************************************"
            echo "** Dump file missing! Create a symlin to your DB backup file:                             **"
            echo "** ln -s PATH/TO/GZIPPED/MYSQLDUMP/FILE.sql.gz ./$TARGET_FILE_NAME **"
            echo "********************************************************************************************"
            echo -e "${Color_Off}"
        else
            echo -e "${Red}ERROR: File $TARGET_FILE_NAME does not exists${Color_Off}"
        fi
        cd $CWD
        exit 1
    fi
    INFO=$(file -b $TARGET_FILE_NAME | cut -d' ' -f1)
    if [ "$INFO" != "gzip" ]; then
        echo -e "${Red}ERROR: File $TARGET_FILE_NAME type is not gzip${Color_Off}"
        cd $CWD
        exit 3
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

    echo -e "${Yellow}Restoring db from:\n $TARGET_FILE_NAME${Color_Off}"
    echo "This may take some time."

    echo
    echo -e "${Yellow}Databases before the restore:${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORE_INFO 2>/dev/null"
    echo
    echo "Please wait..."
    docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORER 2>/dev/null"
    echo
    echo -e "${Yellow}Databases after the restore${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORE_INFO 2>/dev/null"
    echo -e "${Yellow}Users after the restore${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_USERS 2>/dev/null"
  }

function ld_command_restore_help() {
    echo "Import latest db. Optionally provide file name. Dump file must be located in $DATABASE_DUMP_STORAGE -folder."
}
