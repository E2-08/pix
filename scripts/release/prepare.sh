#!/usr/bin/env bash

set -e # https://www.gnu.org/software/bash/manual/bashref.html#The-Set-Builtin
set -o pipefail

# Set colors
RESET_COLOR="$(tput sgr0)"
BOLD=$(tput smso)
OFFBOLD=$(tput rmso)

# Colors (bold)
RED="$(tput bold ; tput setaf 1)"
GREEN="$(tput bold ; tput setaf 2)"
YELLOW="$(tput bold ; tput setaf 3)"
BLUE="$(tput bold ; tput setaf 4)"
CYAN="$(tput bold ; tput setaf 6)"

echo -e "Preparing a new release for ${RED}production${RESET_COLOR}.\n"

# Checks we are on branch 'dev'
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "dev" ];
then
  echo -e "${RED}Wrong branch!${RESET_COLOR} You must be on branch ${GREEN}dev${RESET_COLOR} in order to make a release but your current one is ${RED}${CURRENT_BRANCH}${RESET_COLOR}.\n"
  exit 1
fi

# Checks we have no uncommited changes
if [ -n "$(git status --porcelain)" ];
then
    echo -e "${RED}You have uncommitted changes!${RESET_COLOR} Please commit or stash your changes first.\n"
    git status
    exit 1
fi

NEW_VERSION_TYPE=$1

if [ "$NEW_VERSION_TYPE" != "patch" -a "$NEW_VERSION_TYPE" != "minor" ];
then
  echo -e "${RED}Wrong argument!${RESET_COLOR} Only ${GREEN}patch${RESET_COLOR} or ${GREEN}minor${RESET_COLOR} is allowed.\n"
  exit 1
fi

OLD_PACKAGE_VERSION=$(cat package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

npm version $NEW_VERSION_TYPE --git-tag-version=false >> /dev/null

ROOT_PATH=`pwd`

cd $ROOT_PATH/api/ && npm version $NEW_VERSION_TYPE --git-tag-version=false >> /dev/null
cd $ROOT_PATH/live/ && npm version $NEW_VERSION_TYPE --git-tag-version=false >> /dev/null

cd $ROOT_PATH

# Creates new release branch
# https://gist.github.com/DarrenN/8c6a5b969481725a4413
PACKAGE_VERSION=$(cat package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

git add . -u
git commit -m "[RELEASE] A ${NEW_VERSION_TYPE} is being released from ${OLD_PACKAGE_VERSION} to ${PACKAGE_VERSION}."

git tag -a "v${PACKAGE_VERSION}" -m "[RELEASE] A ${NEW_VERSION_TYPE} is being released from ${OLD_PACKAGE_VERSION} to ${PACKAGE_VERSION}."

git push origin dev && git push origin dev --tags

# Fetches all last changes
git pull

# Reinstall all dependencies
npm run clean && npm install

# Remove local branch 'release' if exists, then create it
RELEASE_BRANCH="release-$PACKAGE_VERSION"
if git rev-parse --quiet --verify $RELEASE_BRANCH > /dev/null;
then
    git branch -D $RELEASE_BRANCH
fi

git checkout -b $RELEASE_BRANCH
echo -e "You are now on branch ${YELLOW}$RELEASE_BRANCH${RESET_COLOR}.\n"

echo -e "From now edit the ${CYAN}CHANGELOG.md${RESET_COLOR} file and then execute ${CYAN}release:perform${RESET_COLOR} NPM task.\n"

echo -e "Release preparation ${GREEN}succeeded${RESET_COLOR}."
