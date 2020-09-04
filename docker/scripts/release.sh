#!/usr/bin/env bash
# File
#
# This file ise used to create a new release for local-docker.




# Cross-OS way to do in-place find-and-replace with sed.
# Use: replace_in_file PATTERN FILENAME
function replace_in_file () {
    sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}


MAIN_FILE='ld.sh'
if [ ! -f "$MAIN_FILE" ]; then
  echo "ERROR: Coudld not locate the main file $MAIN_FILE."
  echo "ERROR: Make sure you run this script from the project root."
  exit 1
fi


RELEASE_TAG=${1}
if [ -z "$RELEASE_TAG" ]; then
  echo "ERROR: Missing a tag."
  exit 2
fi

FOUND=$( git tag | grep $RELEASE_TAG | wc -l)
if [ "$FOUND" -ne "0" ]; then
  echo 'ERROR: Tag exists.'
  exit 3
fi

if [[ ! "$RELEASE_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Invalid tag. Use pattern x.y.z (MAJOR.MINOR.PATCH)"
  exit 4
fi

BRANCH=`git rev-parse --abbrev-ref HEAD`
if [ "$BRANCH" != "main" ]; then
  echo "You are on a wrong branch: $BRANCH"
  echo "Releases shall be done solely on main."
  exit 5
fi

CURRENT=$(grep '^LOCAL_DOCKER_VERSION' $MAIN_FILE | cut -d '='  -f2);

echo "Using tag $RELEASE_TAG"
echo "Currently versioned as $CURRENT"

PATTERN1="s|^LOCAL_DOCKER_VERSION=${CURRENT}$|LOCAL_DOCKER_VERSION=${RELEASE_TAG}|"
echo "Regex pattern: $PATTERN1"
replace_in_file $PATTERN1 $MAIN_FILE

git add -p $MAIN_FILE
git commit -m "Release $RELEASE_TAG"
git tag $RELEASE_TAG

PATTERN2="s|^LOCAL_DOCKER_VERSION=${RELEASE_TAG}|LOCAL_DOCKER_VERSION=${CURRENT}|"
echo "Regex pattern: $PATTERN1"
replace_in_file $PATTERN2 $MAIN_FILE

git add -p $MAIN_FILE
git commit -m "Reverting version to $CURRENT"

git log -q --graph --oneline -5
echo 'Tag changed back and forth in the main file.'
echo 'Two commits and a release tag created.'
echo 'If everything is fine push commits and tags to remote.'
