#
# Copyright 2016 The Symphony Software Foundation
#
# Licensed to The Symphony Software Foundation (SSF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#
#!/bin/bash

###
#
# download-files.sh - Runs curl multiple times to fetch files
# from remote web servers.
#
# Configured using environment variables:
# - DOWNLOAD_PATH - path of the folder where files are downloaded; the script will create this folder, if it doesn't exist
# - DOWNLOAD_HOST - the hostname to fetch files from
# - DOWNLOAD_ITEMS - a comma-separated list of URL paths that identify the remote files to download
#
###

if [[ -z "$DOWNLOAD_HOST" ]]; then
  echo "Error on download-files.sh - cannot find DOWNLOAD_HOST environment variable"
  exit -1
fi

if [[ -z "$DOWNLOAD_ITEMS" ]]; then
  echo "Error on download-files.sh - cannot find DOWNLOAD_ITEMS environment variable"
  exit -1
fi

if [[ -z "$DOWNLOAD_PATH" ]]; then
  DOWNLOAD_PATH="."
fi

mkdir -p $DOWNLOAD_PATH
if [[ -n "$DOWNLOAD_DEBUG" ]]; then echo "Downloading certs on $DOWNLOAD_PATH folder"; fi

CURL_VERBOSE=""
if [[ -n "$DOWNLOAD_DEBUG" ]]; then
  CURL_VERBOSE="-v"
fi

for SUFFIX in $(echo $DOWNLOAD_ITEMS | sed "s/,/ /g")
do
  if [[ -n "$DOWNLOAD_DEBUG" ]]; then echo "Downloading cert..."; fi
  FILE_NAME=$(basename $SUFFIX)
  # curl -s -L https://$DOWNLOAD_HOST/$SUFFIX > $DOWNLOAD_PATH/$FILE_NAME
  curl $CURL_VERBOSE -s -L --connect-timeout 60 https://$DOWNLOAD_HOST/$SUFFIX > $DOWNLOAD_PATH/$FILE_NAME
  if [[ -n "$DOWNLOAD_DEBUG" ]]; then echo "Cert $DOWNLOAD_PATH/$FILE_NAME downloaded"; ls -l $DOWNLOAD_PATH/$FILE_NAME; fi
done

if [[ -n "$DOWNLOAD_DEBUG" ]]; then echo "listing certs..."; ls -la $DOWNLOAD_PATH ; fi

exit 0
