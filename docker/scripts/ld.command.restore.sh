#!/usr/bin/env bash
# File
#
# This file contains restore -command for local-docker script ld.sh.

function ld_command_restore_exec() {
    TARGET_FILE_NAME=${1:-${DATABASE_DUMP_STORAGE}/db-container-dump-LATEST.sql.gz}
    TARGET_DB=${2:-}
    COMMAND_SQL_DB_RESTORE_INFO="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -e 'show databases'"
    COMMAND_SQL_DB_USERS="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -D mysql -e \"SELECT User, Host from mysql.user WHERE User NOT LIKE 'mysql%';\""
    COMMAND_SQL_DB_RESTORER="gunzip < ${TARGET_FILE_NAME} | mysql --host "${CONTAINER_DB:-db}" -uroot -p"$MYSQL_ROOT_PASSWORD""
    if [ -n "${TARGET_DB}" ]; then
      COMMAND_SQL_DB_RESTORER="${COMMAND_SQL_DB_RESTORER} ${TARGET_DB}"
    fi

    if [ ! -e "$TARGET_FILE_NAME" ]; then
        if [ -z "$1" ]; then
            echo -e "${Red}"
            echo "********************************************************************************************"
            echo "** Dump file missing! Create a symlink to your DB backup file:                             **"
            echo "** ln -s PATH/TO/GZIPPED/MYSQLDUMP/FILE.sql.gz ./$TARGET_FILE_NAME **"
            echo "********************************************************************************************"
            echo -e "${Color_Off}"
        else
            echo -e "${Red}ERROR: File $TARGET_FILE_NAME does not exist${Color_Off}"
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
    [ "$LD_VERBOSE" -ge "1" ] && echo "This may take some time."

    echo
    if [ "$LD_VERBOSE" -ge "1" ]; then
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
    fi
  }

function ld_command_restore_help() {
    echo "Import db into container. Accepts two optional arguments: 1: location of file if other than ${DATABASE_DUMP_STORAGE}/db-container-dump-LATEST.sql.gz; 2: target database, unless restoring complete schema, as created by the command './ld dump'."
}
