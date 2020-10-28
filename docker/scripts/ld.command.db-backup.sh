#!/usr/bin/env bash
# File
#
# This file contains db-backup -command for local-docker script ld.sh.

# Create a backup of one database.
function ld_command_db-backup_exec() {
    DBNAME=${1:-${MYSQL_DATABASE:-drupal}}
    if [ -z "$DBNAME" ]; then
      echo -e "${Red}ERROR: No database name provided nor found.${Color_Off}"
      return 1
    fi

    DATE=$(date +%Y-%m-%d--%H-%M-%S)
    FILENAME="db-backup--${DBNAME}--$DATE.sql.gz"
    COMMAND_SQL_DB_DUMPER="mysqldump --host "${CONTAINER_DB:-db}" -uroot -p"$MYSQL_ROOT_PASSWORD" --lock-all-tables --compress --flush-logs --flush-privileges  --dump-date --tz-utc --verbose ${DBNAME} 2>/dev/null | gzip --fast -f > /var/db_dumps/${FILENAME}"

    db_connect
    RET="$?"
    case "$RET" in
        1|"1")
          echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
          return $RET
          ;;

        2|"2")
          COMM=$(compose_command) " -f $DOCKER_COMPOSE_FILE  up -d $CONTAINER_DB"
          [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Yellow}Starting DB container for backup purposes.${Color_Off}"
          $COMM
          STARTED=1
          ;;

        3|"3")
         echo -e "${Red}ERROR: DB container not running (or not yet created).${Color_Off}"
         return $RET
       ;;
    esac

    [ "$LD_VERBOSE" -ge "1" ] && echo -e "${Yellow}Using datestamp: $DATE${Color_Off}"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}NEXT: "$(compose_command) " -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c $COMMAND_SQL_DB_DUMPER${Color_Off}"

    $(compose_command) -f $DOCKER_COMPOSE_FILE exec -T ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_DUMPER"
    cd $PROJECT_ROOT/${DATABASE_DUMP_STORAGE:-db_dumps}
    ln -sf ${FILENAME} db-backup--${DBNAME}--LATEST.sql.gz

    if [ -n "$STARTED" ]; then
       [ "$LD_VERBOSE" -ge "1" ] && echo -e "${Yellow}Stopping DB container.${Color_Off}"
       COMM=$(compose_command) " -f $DOCKER_COMPOSE_FILE stop $CONTAINER_DB"
        [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
       $COMM
    fi

    echo "DB backup of database ${DBNAME} in ${DATABASE_DUMP_STORAGE:-db_dumps}/${FILENAME}"
    echo "DB backup of ${DBNAME} symlinked from: ${DATABASE_DUMP_STORAGE:-db_dumps}/db-backup--${DBNAME}--LATEST.sql.gz"

}

function ld_command_db-backup_help() {
    echo -e "Backup a ${BBlack}single${Color_Off} database. Optionally provide database name (default: ${MYSQL_DATABASE:-drupal}). Dump file will be place in ${DATABASE_DUMP_STORAGE:-db_dumps} -folder."
}
