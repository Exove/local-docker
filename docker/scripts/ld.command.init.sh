#!/usr/bin/env bash
# File
#
# This file contains init -command for local-docker script ld.sh.

function ld_command_init_exec() {

    DOCKER_COMPOSER_ONLY_FILE=./docker/docker--composer-only.yml

    if ! project_config_file_check; then
        echo -e "${BRed}This project is already initialized. ${Color_Off}"
        echo -e "${Yellow}Are you really sure you want to re-initialize the project? ${Color_Off}"
        read -p "[yes/NO] " ANSWER
        # Lowercase.
        ANSWER="$(echo ${ANSWER} | tr [A-Z] [a-z])"
        case "$ANSWER" in
            'y'|'yes')
                if [ -e "$DOCKERSYNC_FILE" ] || [ -e "$DOCKER_COMPOSE_FILE" ]; then
                    echo -e "${BYellow}WARNING: ${Yellow}There is docker-compose and/or docker-sync configuration (.yml) files in project root.${Color_Off}"
                    echo -e "${Yellow}If you continue and rename your volumes ${BYellow}you may lose data (database).${Color_Off}"
                    echo -e "${Yellow}It is highly recommended to backup your database before continuing:${Color_Off}"
                    echo -e "${Yellow}./ld db-dump${Color_Off}"
                    read -p "Remove these files? [Y/n/cancel] " CHOICE
                    CHOICE="$(echo ${CHOICE} | tr [A-Z] [a-z])"
                    case "$CHOICE" in
                        y|'yes'|'') rm -f $DOCKERSYNC_FILE $DOCKER_COMPOSE_FILE 6& echo "Removed." ;;
                        n|'no'|c|'cancel') echo "Cancelled reinitialization of docker-compose/docker-sync config." && exit 1;;
                    esac
                fi
                ;;
            *)
              echo -e "${BRed}Initialization cancelled.${Color_Off}"
              return;
              ;;
        esac
    fi

    # Check first to flatten the git repo history fully.
    # Git repo must match local-docker origin and commit has be known initial
    # commit has of local-docker.
    # Without these matching nothing will be done.
    $SCRIPT_NAME git-repo-massage

    echo
    echo -e "${BBlack}== General setup ==${Color_Off}"

    define_configuration_value LOCAL_DOCKER_VERSION_INIT $LOCAL_DOCKER_VERSION
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}Initializing with local-docker version: ${BYellow}${LOCAL_DOCKER_VERSION}${Yellow}.${Color_Off}"

    # Project type, defaults to common.
    TYPE=${1:-'common'}
    # Read all template files available for whitelist.
    WHITELIST_TYPES=$(find ./docker -maxdepth 1 -name 'docker-compose.*.yml' -print0 | xargs -0 basename -a | cut -d'.' -f2 | xargs)
    if [[ " ${WHITELIST_TYPES[@]} " != *" $TYPE "* ]]; then
        echo
        echo -e "${Red}The requested template ${BRed}\"$TYPE\"${Red} is not available.. ${Color_Off}"
        echo -e "${Yellow}Available templates include: ${WHITELIST_TYPES[@]}. ${Color_Off}"
        echo
        exit 1
    fi


    VALID=0
    while [ "$VALID" -eq "0" ]; do
        echo
        echo  -e "${BBlack}== Project name == ${Color_Off}"
        echo  "Provide a string using characters a-z, 0-9, - and _ (no dots, must start and end with a character a-z)."
        PROJECT_NAME=${PROJECT_NAME:-$(basename $PROJECT_ROOT)}
        read -p "Project name ['$PROJECT_NAME']: " ANSWER
        # Lowercase.
        ANSWER="$(echo ${ANSWER} | tr [A-Z] [a-z])"
        if [ -z "$ANSWER" ]; then
            VALID=1
        elif [[ "$ANSWER" =~  ^(([a-z])([a-z0-9\-]*))?([a-z])$ ]]; then
            PROJECT_NAME=$ANSWER
            VALID=1
        else
            echo -e "${Red}ERROR: Project name can contain only alphabetic characters (a-z), numbers (0-9) and hyphen (-).${Color_Off}"
            echo -e "${Red}ERROR: Also the project name must not start or end with hyphen or number.${Color_Off}"
            sleep 2
            echo
        fi
    done
    # Remove spaces.
    PROJECT_NAME=$(echo "$PROJECT_NAME" | sed 's/[[:space:]]/-/g')

    define_configuration_value PROJECT_NAME $PROJECT_NAME
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}Project name is: ${BYellow}${PROJECT_NAME}${Yellow}.${Color_Off}"

    VALID=0
    while [ "$VALID" -eq "0" ]; do
        echo
        echo  -e "${BBlack}== Local development base domain == ${Color_Off}"
        echo -e "Do not add protocol nor www part but just the domain name. It is recommended to use domain ending with ${BBlack}.local${Black}.${Color_Off}"
        DEFAULT=${PROJECT_NAME}.local
        LOCAL_DOMAIN=${LOCAL_DOMAIN:-${DEFAULT}}
        read -p "Domain [$LOCAL_DOMAIN] " ANSWER
        # Lowercase.
        ANSWER="$(echo ${ANSWER} | tr [A-Z] [a-z])"
        TEST=$(echo $ANSWER | egrep -e '^(([a-zA-Z0-9])([a-zA-Z0-9\.]*))?([a-zA-Z0-9])$')
        if [ -z "$ANSWER" ]; then
            VALID=1
        elif [ "${#TEST}" -gt 0 ]; then
            LOCAL_DOMAIN=$ANSWER
            VALID=1
        else
            echo -e "${Red}ERROR: Domain name can contain only alphabetic characters (a-z), numbers (0-9), hyphens (-) and dots (.).${Color_Off}"
            echo -e "${Red}ERROR: Also the domain name must not start or end with hyphen or dot.${Color_Off}"
            sleep 2
            echo
        fi
    done
    # Remove spaces.
    LOCAL_DOMAIN=$(echo "$LOCAL_DOMAIN" | sed 's/[[:space:]]/./g')
    define_configuration_value LOCAL_DOMAIN $LOCAL_DOMAIN
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}Local develoment domain is:  ${BYellow}${LOCAL_DOMAIN}${Yellow}.${Color_Off}"

    define_configuration_value DRUSH_OPTIONS_URI "http://www.${LOCAL_DOMAIN}"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}Default URL for Drush is: ${BYellow}${DRUSH_OPTIONS_URI}${Yellow}.${Color_Off}"

    echo
    echo -e "${BBlack}== Local development IP address ==${Color_Off}"
    # Do not re-generate IP if one is set!
    if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "127.0.0.1" ]; then
        [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BGreen}INFO: ${Green}Local development IP is pre-configured to ${LOCAL_IP} in .env file.${Color_Off}"
    else
        echo "Random IP address is recommended for local development. Once can be generated for you now."
        read -p "Generate random IP address [Y/n]? " ANSWER
        # Lowercase.
        ANSWER="$(echo ${ANSWER} | tr [A-Z] [a-z])"
        case "$ANSWER" in
            'n'|'no') LOCAL_IP='127.0.0.1';;
            *) LAST=$((RANDOM % 240 + 3 )) && LOCAL_IP=$( printf "127.0.%d.%d\n" "$((RANDOM % 256))" "$LAST");;
        esac
        # Remove spaces.
        LOCAL_IP=$(echo "$LOCAL_IP" | sed 's/[[:space:]]/./g')
        define_configuration_value LOCAL_IP $LOCAL_IP
    fi
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}IP address is: ${BYellow}${LOCAL_IP}${Yellow}.${Color_Off}"

    echo
    echo -e "${BBlack}== PHP version ==${Color_Off}"
    while [ -z "$PROJECT_PHP_VERSION" ]; do
        echo "What is the PHP version to use?"
        echo "Options:"
        echo " [1] - PHP 7.1"
        echo " [2] - PHP 7.2"
        echo " [3] - PHP 7.3 (default)"
        read -p "Select version: " VERSION
        case "$VERSION" in
            ''|'3'|3) PROJECT_PHP_VERSION='7.3';;
            '2'|2) PROJECT_PHP_VERSION='7.2';;
            '1'|1) PROJECT_PHP_VERSION='7.1';;
            *) echo -e "${Red}ERROR: PHP version selection failed. Please use the available options.${Color_Off}"
        esac
    done
    define_configuration_value PROJECT_PHP_VERSION $PROJECT_PHP_VERSION
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}Using PHP version: ${BYellow}$PROJECT_PHP_VERSION${Yellow}.${Color_Off}"

    echo
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${BYellow}INFO: ${Yellow}Setting up docker-compose and docker-sync files for project type '${BYellow}$TYPE${Yellow}'."

    # Skeleton and DDEV tend to use different folder as the main location for app code.
    [[ "$TYPE" == "skeleton" ]] &&  APP_ROOT='drupal'
    [[ "$TYPE" == "ddev" ]] &&  APP_ROOT='.'

    yml_move $TYPE
    if [ "$?" -eq "1" ]; then
      echo -e "${Red}ERROR: Moving YML files for Docker Compose and Docker Sync failed.${Color_Off}"
      return 1
    fi

    echo
    APP_ROOT=${APP_ROOT:-app}
    define_configuration_value APP_ROOT $APP_ROOT
    ensure_folders_present $APP_ROOT
    echo -e "${BYellow}INFO: ${Yellow}Application root is in ${BYellow}$APP_ROOT${Yellow}.${Color_Off}"

    DATABASE_DUMP_STORAGE=${DATABASE_DUMP_STORAGE:-db_dumps}
    define_configuration_value DATABASE_DUMP_STORAGE $DATABASE_DUMP_STORAGE
    ensure_folders_present $DATABASE_DUMP_STORAGE
    echo -e "${BYellow}INFO: ${Yellow}Database dumps will be placed in ${BYellow}$DATABASE_DUMP_STORAGE${Yellow}.${Color_Off}"

    if [[ "$(docker-compose -f $DOCKER_COMPOSE_FILE ps -q)" ]]; then
        echo -n "Turning off current container stack, please wait..."
        docker-compose -f $DOCKER_COMPOSE_FILE down 2> /dev/null
        echo  -e "${Green}DONE${Color_Off}"
    fi

    # Docker-sync shouldn't be running to avoid it getting stuck with too
    # may files being changed in a short period of time. Temporary Composer
    # container does not use these volumes.
    # "rename-volumes" will also turn off & clean docker-sync.
    $SCRIPT_NAME rename-volumes $PROJECT_NAME

    if [ -e "${APP_ROOT}/composer.json" ]; then
        echo -e "${Yellow}Looks like project is already created? File ${APP_ROOT}/composer.json exists.${Color_Off}"
        echo -e "${Yellow}Maybe you should install codebase using composer:${Color_Off}"
        echo -e "${Yellow}$SCRIPT_NAME_SHORT up && $SCRIPT_NAME_SHORT composer install${Color_Off}"
        cd $CWD
        return 1
    fi

    echo
    echo -e "${Yellow}Starting a temporary ${BYellow}Composer${Yellow} container only for the codebase building, please wait...${Color_Off}"
    docker-compose -f $DOCKER_COMPOSER_ONLY_FILE up -d
    echo -e "${BGreen}Composer${Green} container started.${Color_Off}"

    echo
    echo "Verify application root can be used to install codebase (must be empty)..."

    FILE_COUNTER='find /var/www -maxdepth 1 | egrep -v "^\/var\/www$" | wc -l'
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T composer bash -c \"$FILE_COUNTER\"${Color_Off}"
    [ "$LD_VERBOSE" -ge "2" ] && echo -n "Files (count) in ./${APP_ROOT}: "
    APP_FILES_COUNT=$(docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T composer bash -c "$FILE_COUNTER")
    # Clean up response from newlines and stuff to make it integer~ish.
    APP_FILES_COUNT=$(echo $APP_FILES_COUNT |tr -d '\r' |tr -d '\n' |tr -d ' ')

    if [ "$LD_VERBOSE" -ge "2" ]; then
        [ -n "$APP_FILES_COUNT" ] && [ "$APP_FILES_COUNT" -eq "0" ] && echo -e "${APP_FILES_COUNT} - ${BGreen}CLEAN${Color_Off}" || echo -e " - ${Red}ERROR${Color_Off}"
        sleep 1
    fi

    COMPOSER_INIT=
    POST_COMPOSER_INIT=

    if [ -z "$APP_FILES_COUNT" ]; then
        echo -e "${Red}ERROR: Could not check files count in application root ./${APP_ROOT}.${Color_Off}"
        docker-compose -f $DOCKER_COMPOSER_ONLY_FILE down
        return 1
    elif [ "$APP_FILES_COUNT" -ne "0" ]; then
        echo "Application root folder ./$APP_ROOT is not empty. Installation requires an empty folder."
        echo "Current folder contents:"
        ls -A $APP_ROOT
        echo -en "${Red}WARNING: If you continue all of these will be deleted. ${Color_Off}"
        read -p "Type 'PLEASE-DELETE' to continue: " ANSWER
        # Lowercase.
        ANSWER="$(echo ${ANSWER} | tr [A-Z] [a-z])"
        case "$ANSWER" in
            'PLEASE-DELETE' )
                echo "Clearing old things from the app root."
                CLEAN_ROOT="rm -rf /var/www/{,.[!.],..?}*"
                [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T composer bash -c \"$CLEAN_ROOT\"${Color_Off}"
                docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T composer bash -c "$CLEAN_ROOT"
                ;;
            *)
                echo -e "${Red}ERROR: Application can't be installed to a non-empty folder ./${APP_ROOT}.${Color_Off}"
                docker-compose -f $DOCKER_COMPOSER_ONLY_FILE down
                return 1
                ;;
        esac
    fi

    echo
    echo -e "${BBlack}== Generating SSL/TLS certificates ==${Color_Off}"
    $SCRIPT_NAME tls-cert

    echo
    echo -e "${BBlack}== Installing Drupal project ==${Color_Off}"
    DEFAULT=9.0

    echo "Please select which version of drupal you wish to have."
    echo "Alternatively you can install your codebase manually into $APP_ROOT."
    echo "Options:"
    echo " [9.0] - Drupal 8.9 recommended (drupal/recommended-project:~9.0.0)"
    echo " [9.0-dev] - Drupal 9.0 recommended (drupal/recommended-project:~9.0.0) with dev-stability"
    echo " [8.9] - Drupal 8.9 recommended (drupal/recommended-project:~8.9.0)"
    echo " [8.9-dev] - Drupal 8.9 recommended (drupal/recommended-project:~8.9.0) with dev-stability"
    echo " [8.8] - Drupal 8.8 recommended (drupal/recommended-project:~8.8.0)"
    echo " [8.8-dev] - Drupal 8.8 recommended (drupal/recommended-project:~8.8.0) with dev-stability"
    echo " [8.8-legacy] - Drupal 8.8 legacy (drupal/legacy-project:~8.8.0)"
    echo " [N] - Thanks for the offer, but I'll handle codebase build manually."
    read -p "Select version [default: ${DEFAULT}]? " VERSION
    VERSION=${VERSION:-${DEFAULT}}
    case "$VERSION" in
      '9.0')
        COMPOSER_INIT='composer -vv create-project drupal/recommended-project:~9.0.0 . --no-interaction'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 9.0.x${Green}, recommended structure (${BGreen}drupal/recommended-project:~9.0.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      '9.0-dev')
        COMPOSER_INIT='composer -vv create-project drupal/recommended-project:~9.0.0 . --no-interaction --stability=dev'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 9.0.x (dev)${Green}, recommended structure (${BGreen}drupal/recommended-project:~9.0.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      '8.9')
        COMPOSER_INIT='composer -vv create-project drupal/recommended-project:~8.9.0 . --no-interaction'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 8.9.x${Green}, recommended structure (${BGreen}drupal/recommended-project:~8.9.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      '8.9-dev')
        COMPOSER_INIT='composer -vv create-project drupal/recommended-project:~8.9.0 . --no-interaction --stability=dev'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 8.9.x (dev)${Green}, recommended structure (${BGreen}drupal/recommended-project:~8.9.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      '8.8')
        COMPOSER_INIT='composer -vv create-project drupal/recommended-project:~8.8.0 /var/www --no-interaction'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 8.8.x${Green}, recommended structure (${BGreen}drupal/recommended-project:~8.8.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      '8.8-dev')
        COMPOSER_INIT='composer -vv create-project drupal/recommended-project:~8.8.0 /var/www --no-interaction --stability=dev'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 8.8.x (dev)${Green}, recommended structure (${BGreen}drupal/recommended-project:~8.8.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      '8.8-legacy')
        COMPOSER_INIT='composer -vv create-project drupal/legacy-project:~8.8.0 /var/www --no-interaction --stability=dev'
        POST_COMPOSER_INIT='composer -vv require drupal/console:^1.9.4 drush/drush:^10.0 cweagans/composer-patches:~1.0'
        echo -e "${Green}Creating project using ${BGreen}Drupal 8.8.x${Green}, legacy structure (${BGreen}drupal/legacy-project:~8.8.0${Green}), with the addition of Drupal Console, Drush and composer patches.${Color_Off}"
        ;;
      *)
        echo -e "${BYellow}Build phase skipped, no codebase built!${Color_Off}"
        ;;
    esac

    if [ -n "$COMPOSER_INIT" ]; then
      # Use verbose output on this composer command.
      [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T php bash -c \"COMPOSER_MEMORY_LIMIT=-1 $COMPOSER_INIT\"${Color_Off}"
      # Turn off PHP memory limit for the create project -phase (only).
      docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T composer bash -c "COMPOSER_MEMORY_LIMIT=-1  $COMPOSER_INIT"
      OK=$?
      if [ "$OK" -ne "0" ]; then
          echo -e "${BRed}ERROR${Red}: Something went wrong when initializing the codebase.${Color_Off}"
          echo -e "${Red}Check that required ports are not allocated (by other containers or programs) and re-configure them if needed.${Color_Off}"
          docker-compose -f $DOCKER_COMPOSER_ONLY_FILE down
          cd $CWD
          return 1
      fi
      if [ -n "$POST_COMPOSER_INIT" ]; then
          # Use verbose output on this composer command.
          [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T php bash -c \"COMPOSER_MEMORY_LIMIT=-1 $POST_COMPOSER_INIT\"${Color_Off}"
          # Turn off PHP memory limit for these commands.
          docker-compose -f $DOCKER_COMPOSER_ONLY_FILE exec -T composer bash -c "COMPOSER_MEMORY_LIMIT=-1 $POST_COMPOSER_INIT"
      fi

      echo
      echo -e "${Green}Project created to ./$APP_ROOT folder (/var/www in containers).${Color_Off}"
    else
      echo -e "${Green}Project root is set to ./$APP_ROOT folder (/var/www in containers).${Color_Off}"
    fi

    docker-compose -f $DOCKER_COMPOSER_ONLY_FILE down

    if [ "$LD_VERBOSE" -ge "1" ] ; then
        echo
        echo -e "${BGreen}*******************************${Color_Off}"
        echo -e "${BGreen}***** Project initialized *****${Color_Off}"
        echo -e "${BGreen}*******************************${Color_Off}"
        echo
    fi
    if [ -z "$COMPOSER_INIT" ]; then
        echo
        echo -e "${Yellow}NOTE: Once Drupal is installed, you should remove write perms in sites/default -folder:${Color_Off}"
        echo "docker-compose -f $DOCKER_COMPOSE_FILE exec -T php bash -c 'chmod -v 0755 web/sites/default'"
        echo "docker-compose -f $DOCKER_COMPOSE_FILE exec -T php bash -c 'chmod -v 0644 web/sites/default/settings.php'"
        echo "With these changes you can edit settings.php from host, but keep Drupal happy and allow it to write these files."
    fi

    if [ "$LD_VERBOSE" -ge "1" ] ; then
        echo
        echo -e "${BGreen}Booting up the project now, please wait...${Color_Off}"
        echo
    fi
    $SCRIPT_NAME up
    # This must be run after composer install.
    $SCRIPT_NAME drupal-structure-fix
    $SCRIPT_NAME drupal-files-folder-perms

    $SCRIPT_NAME info
}

function ld_command_init_help() {
    echo "Builds the project (default: codebase in./app -folder, use composer, use drupal-project)"
}
