#!/bin/bash

# This script is inspired by https://gist.github.com/willprice/e07efd73fb7f13f917ea
# and provides a configurable way to push artifacts to git (defaults to github.com)
#
# The git target repository/branch is identified by:
# - GIT_ORG (mandatory)
# - GIT_REPO (mandatory)
# - GIT_HOST (optional, defaults to "github.com")
# - GIT_BRANCH (optional, defaults to "github.com")
#
# The git user that runs these operations is identified by:
# - GIT_TOKEN (mandatory)
# - GIT_USER_NAME (mandatory)
# - GIT_USER_EMAIL (mandatory)
#
# The commit operations executed by the script are identified by:
# - FILES_TO_PUSH (optional, defaults to "*")
# - COMMIT_MESSAGE_EXTRA (optional, defaults to "")

if [[ -z "$GIT_TOKEN" ]]; then
  echo "Missing GIT_TOKEN env variable. Quitting."
  exit -1
fi

if [[ -z "$GIT_ORG" ]]; then
  echo "Missing GIT_ORG env variable. Quitting."
  exit -1
fi

if [[ -z "$GIT_REPO" ]]; then
  echo "Missing GIT_REPO env variable. Quitting."
  exit -1
fi

if [[ -z "$GIT_USER_NAME" ]]; then
  echo "Missing GIT_USER_NAME env variable. Quitting."
  exit -1
fi

if [[ -z "$GIT_USER_EMAIL" ]]; then
  echo "Missing GIT_USER_EMAIL env variable. Quitting."
  exit -1
fi


if [[ -z "$GIT_HOST" ]]; then
  export GIT_HOST="github.com"
fi

if [[ -z "$GIT_BRANCH" ]]; then
  export GIT_BRANCH="master"
fi

if [[ -z "$FILES_TO_PUSH" ]]; then
  export FILES_TO_PUSH="*"
fi

setup_git() {
  git config --global user.email $GIT_USER_EMAIL >/dev/null
  git config --global user.name $GIT_USER_NAME >/dev/null
  echo "Configured git user name and email"
}

checkout_project() {
  # remove any existing checkout, if there
  rm -rf ${GIT_REPO}-checkout

  # clone the git repo where we need to push and checkout the right branch
  git clone -q https://${GIT_TOKEN}@${GIT_HOST}/${GIT_ORG}/${GIT_REPO}.git ${GIT_REPO}-checkout >/dev/null
  cd ${GIT_REPO}-checkout
  git checkout -q $GIT_BRANCH >/dev/null
  echo "Checked out project on ${PWD}"
}

push_files() {
  # copy the artifacts from the current project into the git repo checkout
  echo "copy artifact from folder ${PWD}"
  cp -rf ../${FILES_TO_PUSH} .

  git add $FILES_TO_PUSH
  git commit -q -m "$GIT_USER_NAME is pushing $FILES_TO_PUSH $COMMIT_MESSAGE_EXTRA"
  git push -q -u origin $GIT_BRANCH >/dev/null
  echo "Pushed changes into remote git repo"
}

cleanup() {
  cd ..
  rm -rf ${GIT_REPO}-checkout
}

setup_git
checkout_project
push_files
cleanup
