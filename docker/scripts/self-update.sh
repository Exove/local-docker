#!/usr/bin/env bash
# File
#
# This file contains self-update -command for local-docker script ld.sh.
# Get colors.
if [ ! -f "./docker/scripts/ld.colors.sh" ]; then
    echo "File ./docker/scripts/ld.colors.sh missing."
    echo "You are currently in "$(pwd)
    exit 1;
fi
. ./docker/scripts/ld.colors.sh

# Check if there are untracked or unstaged changes.
MODIFIED_FILES=$(( $(git ls-files -m --exclude-standard | wc -l) ))
[[ $MODIFIED_FILES -ne 0 ]] && \
    CHANGES="${MODIFIED_FILES} modified"
UNTRACKED_FILES=$(( $(git ls-files -o --exclude-standard | wc -l) ))
[[ $UNTRACKED_FILES -ne 0 ]] && \
    CHANGES="${CHANGES:+$CHANGES and }${UNTRACKED_FILES} untracked"
if [[ -n ${CHANGES:-} ]] ; then
    echo -e "${Yellow}There are ${CHANGES} files present. It is not recommended to continue without stashing them.${Color_Off}" >&2
    read -r -p "Stash changes including untracked files before proceeding? (Y/n): (^C to abort.)"
    if [[ ! ( $REPLY =~ ^[Nn] ) ]] ; then
        git stash --include-untracked || { echo -e "${Red}ERROR: Could not stash changes, aborting.${Color_Off}" >&2; exit 1; }
        STASHED=1
    fi
fi
# When no tag is provided we'll fallback to use the 'latest'.
TAG=${1:-latest}
TAG_PROVIDED=
if [ -n "$1" ];then
    TAG_PROVIDED=1
fi

# Check the tag exists if one is provided.
if [ -n "$TAG_PROVIDED" ]; then
    echo "Looking for tag ${TAG}, please wait..."
    CURL="curl -sL https://api.github.com/repos/Exove/local-docker/releases/tags/${TAG}"
    EXISTS=$($CURL | grep -e '"name":' -e '"html_url":.*local-docker' -e '"published_at":' -e '"tarball_url":' -e '"body":' | tr '\n' '|')
    if [ -z "$EXISTS"  ]; then
        echo -e "${Red}ERROR: The tag release was not found.${Color_Off}"
        exit 2
    fi
else
    echo "Requesting the latest release info, please wait..."
    # GET /repos/:owner/:repo/releases/latest
    CURL="curl -sL https://api.github.com/repos/Exove/local-docker/releases/latest"
    EXISTS=$($CURL | grep -e '"name":' -e '"html_url":.*local-docker' -e '"published_at":' -e '"tarball_url":' -e '"body":' | tr '\n' '|')
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

DIR=".ld-tmp-"$(date +%s)
mkdir $DIR
# Remove whitespaces we do not wish to deal with in filenames.
RELEASE_NAME_CLEAN=$(echo $RELEASE_NAME | sed -e 's/^[[:space:]]*//')
TEMP_FILENAME="release-${RELEASE_NAME_CLEAN}.tar.gz"
if [ -n "$RELEASE_TARBALL" ]; then
     # Latest git tags is the first one in the file.
    echo -e "Release name : ${BGreen} $RELEASE_NAME${Color_Off}"
    echo -e "Published    : ${BGreen} $RELEASE_PUBLISHED${Color_Off}"
    echo -e "Release page : ${BGreen} $RELEASE_PAGE${Color_Off}"
    echo -e "Release info : "
    echo -e "${BGreen}$RELEASE_BODY${Color_Off}"
    echo
    echo "Downloading release from $RELEASE_TARBALL, please wait..."
    # -L to follow redirects
    curl -L -s -o "$DIR/$TEMP_FILENAME" $RELEASE_TARBALL
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
LIST=" .editorconfig .env.example .env.local.example .gitignore.example ./docker ./git-hooks ld.sh"
for FILE in $LIST; do
    cp -fr "$DIR/$SUBDIR/$FILE" .
done
# Handle README.md separately since it can not override the existing project
# README.md file.
TAG_FOUND=$(grep -c 'DO-NOT-REMOVE-THIS-LINE' ./README.md)
if [ "$TAG_FOUND" -ge "1" ]; then
    LIST="README.md ${LIST}"
    cp -f "$DIR/$SUBDIR/README.md"  README.md
else
    LIST="README.local-docker.md ${LIST}"
    cp -f "$DIR/$SUBDIR/README.md" README.local-docker.md
fi

# Remove temp dir, but take precautions, the DIR value must not remove root (/).
rm -rf "$(pwd)/$DIR"

echo
echo -e "${Green}Local-docker updated to version ${BGreen}${RELEASE_NAME}${Green}.${Color_Off}"
echo
echo -e "${Yellow}Review and commit changes to: "
for FILE in $LIST; do
    echo " - $FILE"
done

echo -e "${Yellow}Optionally update your own .env.local file, too.${Color_Off}"

if [[ -v STASHED ]] ; then
    read -r -p "You had changes that were stashed. Would you like to pop the stash now? (Y/n): "
    if [[ ! ( $REPLY =~ ^[Nn] ) ]] ; then
        git stash pop
    fi
fi
