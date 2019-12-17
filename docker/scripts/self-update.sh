#!/usr/bin/env bash
# File
#
# This file contains self-update -command for local-docker script ld.sh.
# Strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'
# Get colors.
if [ ! -f "./docker/scripts/ld.colors.sh" ]; then
    echo "File ./docker/scripts/ld.colors.sh missing."
    echo "You are currently in "$(pwd)
    exit 1;
fi
. ./docker/scripts/ld.colors.sh

# When no tag is provided we'll fallback to use the 'latest'.
TAG=${1:-latest}

# Check the tag exists if one was provided.
if [ $# -ne 0 ]; then
    echo "Looking for tag ${TAG}, please wait..."
    URL="https://api.github.com/repos/Exove/local-docker/releases/tags/${TAG}"
    EXISTS=$(curl -sL "${URL}" | grep -e '"name":' -e '"html_url":.*local-docker' -e '"published_at":' -e '"tarball_url":' -e '"body":' | tr '\n' '|')
    if [ -z "$EXISTS"  ]; then
        echo -e "${Red}ERROR: The tag release was not found.${Color_Off}"
        exit 2
    fi
else
    echo "Requesting the latest release info, please wait..."
    # GET /repos/:owner/:repo/releases/latest
    URL="https://api.github.com/repos/Exove/local-docker/releases/latest"
    EXISTS=$(curl -sL "${URL}" | grep -e '"name":' -e '"html_url":.*local-docker' -e '"published_at":' -e '"tarball_url":' -e '"body":' | tr '\n' '|')
    if [ -z "$EXISTS"  ]; then
        echo -e "${Red}ERROR: No information about the latest release available.${Color_Off}"
        exit 3
    fi
fi


EXISTS="|$EXISTS"
RELEASE_NAME=$(echo $EXISTS | grep -o -e '|\s*"name":[^|)]*' |cut -d'"' -f4)
RELEASE_PUBLISHED=$(echo $EXISTS | grep -o -e '|\s*"published_at":[^|)]*' |cut -d'"' -f4)
RELEASE_TARBALL=$(echo $EXISTS | grep -o -e '|\s*"tarball_url":[^|)]*' |cut -d'"' -f4)
RELEASE_PAGE=$(echo $EXISTS | grep -o -e '|\s*"html_url":[^|)]*' |cut -d'"' -f4)
RELEASE_BODY=$(echo $EXISTS | grep -o -e '|\s*"body":[^|)]*' |cut -d'"' -f4)
RELEASE_TAG=${RELEASE_PAGE##*tag/}

# Remove whitespaces we do not wish to deal with in filenames.
RELEASE_TAG_CLEAN=$(echo $RELEASE_TAG | sed -e 's/^[[:space:]]*//')
TEMP_FILENAME="release-${RELEASE_TAG_CLEAN}.tar.gz"

# Use system temporary directory if available.
if [[ ( -n "${TMPDIR}" ) && ( -d "${TMPDIR}" ) && ( -w "${TMPDIR}" ) ]] ; then
    DIR="${TMPDIR}/local-docker/${RELEASE_TAG_CLEAN}"
else
    LOCAL_TMP_DIR=1
    DIR=".ld-tmp-"$(date +%s)
fi
mkdir -p $DIR
if [ -n "$RELEASE_TARBALL" ]; then
     # Latest git tags is the first one in the file.
    echo -e "Release name : ${BGreen} $RELEASE_NAME${Color_Off}"
    echo -e "Published    : ${BGreen} $RELEASE_PUBLISHED${Color_Off}"
    echo -e "Release page : ${BGreen} $RELEASE_PAGE${Color_Off}"
    echo -e "Release info : "
    echo -e "${BGreen}$RELEASE_BODY${Color_Off}"
    echo
    if [[ -e "${DIR}/${TEMP_FILENAME}" ]] ; then
        echo -e "Using cached release tarball found at ${DIR}/${TEMP_FILENAME} ..."
    else
        echo "Downloading release from $RELEASE_TARBALL, please wait..."
        # -L to follow redirects
        curl -L -s -o "$DIR/$TEMP_FILENAME" $RELEASE_TARBALL
    fi
fi

# Curl creates an ASCII file out of 404 response. Let's see what we have in the file.
INFO=$(file -b $DIR/$TEMP_FILENAME | cut -d' ' -f1)
if [ "$INFO" != "gzip" ]; then
    echo -e "${Red}ERROR: Downloading the requested release failed.${Color_Off}"
    rm -rf $(pwd)/$DIR
    exit 4
fi

tar xzf "$DIR/$TEMP_FILENAME" -C "$DIR"
SUBDIR=$(ls $DIR |grep local-docker)
UPDATE_TARGETS=(
    ".editorconfig"
    ".env.example"
    ".env.local.example"
    ".gitignore.example"
    "./.github"
    "./docker"
    "./git-hooks"
    "ld.sh"
)
for FILE in "${UPDATE_TARGETS[@]}" ; do
    cp -fr "$DIR/$SUBDIR/$FILE" .
done

# Remove temp dir if it was created under current directory, but take precautions,
# the DIR value must not remove root (/).
[[ ${LOCAL_TMP_DIR-0} -eq 1 ]] && echo rm -rf "$(pwd)/$DIR"

echo
echo -e "${Green}Local-docker updated to version ${BGreen}${RELEASE_NAME}${Green}.${Color_Off}"
echo
echo -e "${Yellow}Review and commit changes to: "
for FILE in "${UPDATE_TARGETS[@]}" ; do
    echo " - $FILE"
done

echo -e "${Yellow}Optionally update your own .env.local file, too.${Color_Off}"

if [[ "${BASH_SOURCE[0]}" == './self-update.sh' ]] ; then
    # We are at project root, and with the script being in project root, it means
    # that we are executing a copy made by docker/scripts/ld.command.self-update.sh
    # so we should remove this temporary copy as the last step of execution.
    rm "${BASH_SOURCE[0]}"
fi
