#!/usr/bin/env bash

LOCAL_DOCKER_VERSION=1.x
LD_VERBOSE=${LD_VERBOSE:-2}

CWD=$(pwd)

PROJECT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
if [[ ! -d "$PROJECT_ROOT" ]]; then PROJECT_ROOT="$PWD"; fi

cd $PROJECT_ROOT

# Get colors.
. ./docker/scripts/ld.colors.sh

# Get functions.
. ./docker/scripts/ld.functions.sh

required_binaries_check
case "$?" in
  1|"1") cd $CWD && echo -e "${Red}Docker is not running. Docker is required to use local-docker.${Color_Off}" && exit 1 ;;
  2|"2") cd $CWD && echo -e "${Red}Docker Compose was not found. It is required to use local-docker.${Color_Off}" && exit 1 ;;
  3|"3") cd $CWD && echo -e "${Red}Git was not found. It is required to use local-docker.${Color_Off}" && exit 1 ;;
esac

# 1st param, The Command.
ACTION=${1-'help'}

# Find all available commands.
for FILE in $(ls ./docker/scripts/ld.command.*.sh ); do
    FILE=$(basename $FILE)
    COMMAND=$(cut -d'.' -f3 <<<"$FILE")
    COMMANDS="$COMMANDS $COMMAND"
done

# Use fixed name, since docker-sync is supposed to be locally only.
DOCKERSYNC_FILE=docker-sync.yml
DOCKER_COMPOSE_FILE=docker-compose.yml
DOCKER_YML_STORAGE=./docker
DOCKER_PROJECT=$(basename $PROJECT_ROOT)


# Get current script name, and use a symlink if it exists.
if [ ! -L "$( basename "$0" .sh)" ]; then
    SCRIPT_NAME=$PROJECT_ROOT/$( basename "$0")
    SCRIPT_NAME_SHORT=./$( basename "$0")
else
    SCRIPT_NAME=$PROJECT_ROOT/$( basename "$0" .sh)
    SCRIPT_NAME_SHORT=./$( basename "$0" .sh)
fi

IGNORE_INIT_STATE=0
COMMANDS_TO_IGNORE_INIT_STATE=("help" "self-update" "init" "git-repo-massage")
element_in "$ACTION" "${COMMANDS_TO_IGNORE_INIT_STATE[@]}"
if [ "$?" -eq "0" ]; then
    IGNORE_INIT_STATE=1
fi

# Read (and create if necessary) the .env.local file, allowing overrides to any of our config values.
if [ "$ACTION" == "init" ]; then
    import_config
fi

if [  "$IGNORE_INIT_STATE" -eq "0" ]; then
    if project_config_file_check; then
        echo -e "${BYellow}This project is not yet initialized. ${Color_Off}"
        echo -e "${Yellow}Initialize the project with: ${Color_Off}"
        echo -e "\$ ${SCRIPT_NAME_SHORT} init"
        cd $CWD
        exit 1;
    fi
    import_config
# Some help instructions utilize config if it exists.
elif [ -f ".env" ]; then
    import_config
fi

FILE=./docker/scripts/ld.command.$ACTION.sh

if [[ -f "$FILE" ]]; then
    . $FILE
    FUNCTION="ld_command_"$ACTION"_exec"
    if function_exists $FUNCTION ; then
        $FUNCTION ${@:2} || echo -e "${Red}ERROR: Command '${ACTION}' failed. Check its output for possible causes or suggestions on how to proceed or fix the issue."
    else
        echo -e "${Red}ERROR: Command not found (hook '$FUNCTION' missing for command $ACTION).${Color_Off}."
    fi
else
    echo -e "${Red}ERROR: Command not found (hook file missing).${Color_Off}."
fi

cd $CWD
