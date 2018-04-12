#!/bin/bash

# Licensed to the Symphony Software Foundation (SSF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SSF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Name: validate-license-source.sh
# Author: maoo@symphony.foundation
# Creation date: 25 May 2016
# Description: Validates source code against Symphony Software Foundation (SSF) acceptance criteria returning a list of issues - https://symphonyoss.atlassian.net/wiki/x/SAAx ; source code can be specified as file-system path or URL pointing to a ZIP file
# Tested on:
# 1. OSX Terminal (SHELL=/bin/zsh)
# 2. Ubuntu 16.04
#
TMP_FOLDER_PARENT=/tmp
TMP_FOLDER=$TMP_FOLDER_PARENT/validate-license-source
LICENSED_TO_SSF_MATCH="Licensed to The Symphony Software Foundation (SSF)"
ASF_LICENSE_MATCH="to you under the Apache License, Version 2.0"
NOTICE_MATCH=("http://symphony.foundation" "Copyright 2016 The Symphony Software Foundation")
LICENSE_MATCH=("http://www.apache.org/licenses/" "Version 2.0, January 2004" "Copyright 2016 The Symphony Software Foundation")
NOT_INCLUDED_LICENSES="All rights reserved\|Binary Code License (BCL)\|GNU GPL 1\|GNU GPL 2\|GNU GPL 3\|GNU LGPL 2\|GNU LGPL 2.1\|GNU LGPL 3\|Affero GPL 3\|NPL 1.0\|NPL 1.1\|QPL\|Sleepycat License\|Microsoft Limited Public License\|Code Project Open License\|CPOL"
ITEM_TO_SCAN=$1
DEFAULT_ITEMS_TO_IGNORE=".*\.jar .*\.classpath .*\.project .*README.* .*\.sln .*\.csproj .*\.json .*\.git)"
REGEX_DEFAULT_IGNORES=$(printf "! -regex %s " $(echo $DEFAULT_ITEMS_TO_IGNORE))

ISSUES_FOUND=0

# Cleaning and creating $TMP_FOLDER
rm -rf $TMP_FOLDER; mkdir -p $TMP_FOLDER

# Parse the (mandatory) folder to scan as first param
if [[ $# -eq 0 ]] ; then
  echo 'validate-license-source.sh'
  echo 'Validates source code against Symphony Software Foundation (SSF) acceptance criteria - https://symphonyoss.atlassian.net/wiki/x/SAAx'
  echo 'Source code can be specified as file-system path or URL pointing to a ZIP file'
  echo ''
  echo 'Usage: ./validate-license-source <folder_to_scan_path|URL_to_zip_file>'
  echo 'Example: curl -sL https://raw.githubusercontent.com/symphonyoss/contrib-toolbox/master/validate-license-source.sh | bash -s -- https://symphonyoss.atlassian.net/secure/attachment/10400/VirtualDesk_Xmpp.zip > report.txt'
  exit 0
fi

if [ -d $ITEM_TO_SCAN ]; then
  FOLDER_TO_SCAN=$1
elif [[ "$ITEM_TO_SCAN" == http* ]]; then
  ITEM_FILE_NAME=`basename $ITEM_TO_SCAN`
  curl -sL $ITEM_TO_SCAN > $TMP_FOLDER/$ITEM_FILE_NAME
  if [[ "$ITEM_TO_SCAN" == *zip ]]; then
    FOLDER_TO_SCAN=$TMP_FOLDER/folder-to-scan
    unzip $TMP_FOLDER/$ITEM_FILE_NAME -d $FOLDER_TO_SCAN > /dev/null
  fi
fi

if [ -f "$FOLDER_TO_SCAN/LICENSE" ]; then
  LICENSE_FILE=$FOLDER_TO_SCAN/LICENSE
elif [ -f "$FOLDER_TO_SCAN/LICENSE.txt" ]; then
  LICENSE_FILE=$FOLDER_TO_SCAN/LICENSE.txt
fi

if [ -f "$FOLDER_TO_SCAN/NOTICE" ]; then
  NOTICE_FILE=$FOLDER_TO_SCAN/NOTICE
elif [ -f "$FOLDER_TO_SCAN/NOTICE.txt" ]; then
  NOTICE_FILE=$FOLDER_TO_SCAN/NOTICE.txt
fi

if [ -z $LICENSE_FILE ]; then
  echo "CRIT-1 - Missing LICENSE file"
  echo ""
  ISSUES_FOUND=1
else
  for match in "${LICENSE_MATCH[@]}"; do
    grep -Li "$match" $LICENSE_FILE > /dev/null
    if [ $? == 1 ]; then
      echo "CRIT-1 - LICENSE file not matching '$match'"
      echo ""
      ISSUES_FOUND=1
    fi
  done
fi

if [ -z $NOTICE_FILE ]; then
  echo "CRIT-2 - Missing NOTICE file"
  ISSUES_FOUND=1
else
  for match in "${NOTICE_MATCH[@]}"; do
    grep -Li "$match" $NOTICE_FILE > /dev/null
    if [ $? == 1 ]; then
      echo "CRIT-2 - NOTICE file not matching '$match'"
      echo ""
      ISSUES_FOUND=1
    fi
  done
fi

# TODO - not working yet
#
# if [ -f $FOLDER_TO_SCAN/.ignore ]; then
#   IGNORE_ITEMS_FROM_FILE="$IGNORE_ITEMS_FROM_FILE $(printf "! -iname %s " $(cat .ignore))"
# fi
# if [ -f $FOLDER_TO_SCAN/.svnignore ]; then
#   IGNORE_ITEMS_FROM_FILE="$IGNORE_ITEMS_FROM_FILE $(printf "! -iname %s " $(cat .svnignore))"
# fi
# if [ -f $FOLDER_TO_SCAN/.gitignore ]; then
#   IGNORE_ITEMS_FROM_FILE="$IGNORE_ITEMS_FROM_FILE $(printf "! -iname %s " $(cat .gitignore))"
# fi

CRIT3_IGNORES="$DEFAULT_ITEMS_TO_IGNORE .*LICENSE.* .*NOTICE.* .*\.git.* .*\.svn.* .*\.sln .*\.csproj .*\.json"
REGEX_CRIT3_IGNORES=$(printf "! -regex %s " $(echo $CRIT3_IGNORES))

RESULTS=`find $FOLDER_TO_SCAN -type f $REGEX_CRIT3_IGNORES $IGNORE_ITEMS_FROM_FILE | xargs -I {} grep -Li "$LICENSED_TO_SSF_MATCH" {}`
if [ -n "$RESULTS" ]; then
  echo "CRIT-3 - List of files not licensed to The Symphony Software Foundation (SSF) ..."
  echo "==========================="
  echo $RESULTS
  echo "==========================="
  echo ""
  ISSUES_FOUND=1
fi

RESULTS=`find $FOLDER_TO_SCAN -type f $REGEX_CRIT3_IGNORES $IGNORE_ITEMS_FROM_FILE | xargs -I {} grep -Li "$ASF_LICENSE_MATCH" {}`
if [ -n "$RESULTS" ]; then
  echo "CRIT-3 - List of files missing Apache license header"
  echo "==========================="
  echo $RESULTS
  echo "==========================="
  echo ""
  ISSUES_FOUND=1
fi

# Find licenses on source files that are incompatible with ASF 2.0
RESULTS=`find $FOLDER_TO_SCAN -type f $REGEX_CRIT3_IGNORES $IGNORE_ITEMS_FROM_FILE | xargs -I {} grep -Ri "$NOT_INCLUDED_LICENSES" {}`

if [ -n "$RESULTS" ]; then
  echo "CRIT-4 - Check source code for incompatible licenses"
  echo "==========================="
  echo $RESULTS
  echo "==========================="
  echo ""
  ISSUES_FOUND=1
fi

# Find licenses on JAR files that are incompatible with ASF 2.0
TMP_EXPLODED_JAR=$TMP_FOLDER/jars
mkdir -p $TMP_EXPLODED_JAR
for jarpath in $(find $FOLDER_TO_SCAN -type f -name \*.jar); do
  jarname=`basename $jarpath`
  mkdir -p $TMP_EXPLODED_JAR/$jarname
  unzip $jarpath -d $TMP_EXPLODED_JAR/$jarname > /dev/null

  # Find licenses on source files that are incompatible with ASF 2.0
  RESULTS=`find $TMP_EXPLODED_JAR/$jarname -type f $REGEX_DEFAULT_IGNORES $IGNORE_ITEMS_FROM_FILE | xargs -I {} grep -Ri "$NOT_INCLUDED_LICENSES" {}`
  if [ -n "$RESULTS" ]; then
    echo "CRIT-4 - Check JAR $jarname for incompatible licenses"
    echo "==========================="
    echo $RESULTS
    echo "==========================="
    echo ""
    ISSUES_FOUND=1
  fi
done

#Deleting $TMP_FOLDER
rm -rf $TMP_FOLDER

if [ "$ISSUES_FOUND" -eq "1" ]; then
  echo "Issues have been found and documented above; to fix them, please visit https://symphonyoss.atlassian.net/wiki/x/SAAx"
  exit 1
else
  echo "No issues found."
  exit 0
fi
