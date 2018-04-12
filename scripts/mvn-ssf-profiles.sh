#!/bin/bash

set -e

# DEPRECATED!
# Please use the following syntax in .travis.yml, as it's easier and way more readable.
# script:
# - "[[ $TRAVIS_BRANCH =~ master ]] && mvn clean deploy -Pintegration-testing,versioneye --settings settings.xml || true"
# - "[[ $TRAVIS_BRANCH =~ dev ]] && mvn clean deploy -Pintegration-testing --settings settings.xml || true"

# This scripts invokes Maven (mvn) using a configurable command ($MVN_COMMAND, defaults to "mvn package") and per-branch profiles
# Set $MVN_MASTER_PROFILES to list profiles you want to use on master (defaults to "versioneye")
# Set $MVN_ALLBRANCHES_PROFILES to list profiles you want to use on all branches but master (defaults to "")

if [ -z "$SCM_BRANCH" ]
then
  SCM_BRANCH=${TRAVIS_BRANCH}
fi  

if [ -z "$MVN_COMMAND" ]
then
  MVN_COMMAND="mvn package"
fi  

if [ -z "$MVN_MASTER_PROFILES" ]
then
  MVN_MASTER_PROFILES="versioneye"
fi  

if [ -z "$MVN_ALLBRANCHES_PROFILES" ]
then
  MVN_ALLBRANCHES_PROFILES=""
fi  

echo "[MVN-SSF] Using Branch $SCM_BRANCH"

if [ "$SCM_BRANCH" = "master" ]; then
  MVN_PROFILES=$MVN_MASTER_PROFILES
else
  MVN_PROFILES=$MVN_ALLBRANCHES_PROFILES
fi

if [ -n "$MVN_PROFILES" ]
then
  MVN_COMMAND="$MVN_COMMAND -P$MVN_PROFILES"
  echo "[MVN-SSF] Invoking mvn using profiles $MVN_PROFILES"
fi

echo "[MVN-SSF] Invoking mvn command: $MVN_COMMAND"
$MVN_COMMAND
