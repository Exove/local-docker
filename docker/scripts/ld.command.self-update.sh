#!/usr/bin/env bash
# File
#
# This file contains self-update -command for local-docker script ld.sh.

SELF_UPDATE_SCRIPT=./docker/scripts/self-update.sh
SELF_UPDATE_TEMP_SCRIPT=./self-update.sh

function ld_command_self-update_exec() {
    # Make a copy of the self-update script itself to avoid the update process
    # breaking when the self-update script itself is changed.
    cp "${SELF_UPDATE_SCRIPT}" "${SELF_UPDATE_TEMP_SCRIPT}"
    # Use the copy to perform the actual update.
    . "${SELF_UPDATE_TEMP_SCRIPT}" "$@"
    # The copy should remove itself, but check anyway.
    if [[ -e "${SELF_UPDATE_TEMP_SCRIPT}" ]] ; then
        echo -e "${Yellow}WARNING: The self-update may have been partially unsuccessfull since a temporary copy of the self-update script failed to remove itself."
        echo -e "You should probably try to run the command again.${Color_Off}"
        read -r -p "Remove the temporary copy ${SELF_UPDATE_TEMP_SCRIPT}? (Y/n): "
        if [[ ! ( $REPLY =~ ^[Nn] ) ]] ; then
            rm "${SELF_UPDATE_TEMP_SCRIPT}"
        fi
    fi
}

function ld_command_self-update_help() {
    echo "Updates local-docker to a specified release, see https://github.com/Exove/local-docker/releases. Defaults to the latest release (may or may not be the latest TAG)."
}
