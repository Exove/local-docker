#!/usr/bin/env bash
# File
#
# This file contains db-import -command for local-docker script ld.sh.

# Restore one database from backup.
function ld_command_db-import_exec() {
    DBNAME=${1:-${MYSQL_DATABASE:-drupal}}
    if [ -z "$DBNAME" ]; then
      echo -e "${Red}ERROR: No database name provided nor found.${Color_Off}"
      return 1
    fi

    TARGET_FILE_NAME=${2:-${DATABASE_DUMP_STORAGE:-db_dumps}/db-backup--${DBNAME}--LATEST.sql.gz}

    COMMAND_SQL_DB_RESTORE_INFO="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -e 'show databases'"
    COMMAND_SQL_DB_RESTORER="gunzip < /var/${TARGET_FILE_NAME} | mysql --host "${CONTAINER_DB:-db}" -uroot -p"$MYSQL_ROOT_PASSWORD" -D ${DBNAME}"
    COMMAND_SQL_DB_USERS="mysql --host "${CONTAINER_DB:-db}" -uroot  -p"$MYSQL_ROOT_PASSWORD" -D mysql -e \"SELECT User, Host from mysql.user WHERE User NOT LIKE 'mysql%';\""

    if [ ! -e "$TARGET_FILE_NAME" ]; then
        if [ -z "$1" ]; then
            echo -e "${Red}"
            echo "************************"
            echo "** Dump file missing! **"
            echo "************************"
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
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORE_INFO 2>/dev/null"
        echo
        echo "Verifying database backup file is found in the container, please wait..."
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "[ -e "/var/${TARGET_FILE_NAME}" ] || echo 'File not found. Please place file inside db_dumps/ folder and provide full path (db_dumps/MY-FILE.tar.gz).'"
        echo "Please wait..."
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORER 2>/dev/null"
        echo
        echo -e "${Yellow}Databases after the restore${Color_Off}"
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_RESTORE_INFO 2>/dev/null"
        echo -e "${Yellow}Users after the restore${Color_Off}"
        $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_USERS 2>/dev/null"
    fi
  }

function ld_command_db-import_help() {
    echo "Import a ${BBlack}single${Color_Off} database from dumpfile. Optionally provide database name (default: ${MYSQL_DATABASE:-drupal}) and dump file location (default: ${DATABASE_DUMP_STORAGE:-db_dumps}/db-backup--${MYSQL_DATABASE:-drupal}--LATEST.sql.gz). Dump file should be located in ${DATABASE_DUMP_STORAGE:-db_dumps} -folder."
}
