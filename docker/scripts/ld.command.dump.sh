#!/usr/bin/env bash
# File
#
# This file contains dump -command for local-docker script ld.sh.

function ld_command_dump_exec() {

    DATE=$(date +%Y-%m-%d--%H-%I-%S)
    COMMAND_SQL_DB_DUMPER="mysqldump --host "${CONTAINER_DB:-db}" -uroot -p"$MYSQL_ROOT_PASSWORD" --all-databases --lock-all-tables --compress --flush-logs --flush-privileges  --dump-date --tz-utc --verbose  2>/dev/null | gzip --fast -f > /var/db_dumps/db-container-dump-$DATE.sql.gz"

    db_connect
    RET="$?"
    case "$RET" in
        1|"1")
          echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
          return $RET
          ;;

        2|"2")
          COMM="docker-compose -f $DOCKER_COMPOSE_FILE  up -d $CONTAINER_DB"
          [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Yellow}Starting DB container for backup purposes.${Color_Off}"
          $COMM
          STARTED=1
          ;;

        3|"3")
         echo -e "${Red}ERROR: DB container not running (or not yet created).${Color_Off}"
         return $RET
       ;;
    esac

    echo -e "${Yellow}Using datestamp: $DATE${Color_Off}"
    docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_DUMPER"
    cd $PROJECT_ROOT/$DATABASE_DUMP_STORAGE
    ln -sf db-container-dump-$DATE.sql.gz db-container-dump-LATEST.sql.gz
    cd $PROJECT_ROOT
    if [ "TESTING${STARTED}" = "TESTING1" ]; then
       echo -e "${Yellow}Stopping DB container.${Color_Off}"
       docker-compose -f $DOCKER_COMPOSE_FILE stop $CONTAINER_DB
    fi
    echo "DB backup in $DATABASE_DUMP_STORAGE/db-container-dump-$DATE.sql.gz"
    echo "DB backup symlink: $DATABASE_DUMP_STORAGE/db-container-dump-LATEST.sql.gz"

}

function ld_command_dump_help() {
    echo "Backup databases to $DATABASE_DUMP_STORAGE -folder"
}
