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

# oc-deploy.sh
#
# This scripts installs Openshift CLI (oc), logs into https://api.preview.openshift.com
# and starts an image build, passing the binaries from file.
# More info on https://docs.openshift.org/latest/dev_guide/builds.html#binary-source

# Environment variables needed:
# - SKIP_OC_INSTALL - The Openshift Online token
# - OC_DELETE_LABEL - If set, it will trigger a 'oc deleta all -l <OC_DELETE_LABEL>; defaults to null'
# - OC_TOKEN - The Openshift Online token; supports branch override
# - OC_TEMPLATE_PROCESS_ARGS - Comma-separated list of env vars to pass to the OC template (ie "BOT_NAME,S2I_IMAGE")
# - OC_ENDPOINT - OpenShift server endpoint; defaults to https://api.starter-us-east-1.openshift.com
# - OC_PROJECT_NAME - The Openshift Online project to use; default is botfarm; supports branch override
# - OC_BINARY_FOLDER - contains the local path to the binary folder to upload to the container as source
# - OC_BINARY_ARCHIVE - contains the local path to the binary archive to upload to the container as source
# - BOT_NAME - the name of the BuildConfig registered in Openshift; supports branch override
# - OC_TEMPLATE - the path of an OpenShift template to execute; if resolved, it will process and create it 
# before the start-build; defaults to '.openshift-template.yaml', if the file exists; supports branch override

# Environment variables overrides:
# - OC_VERSION
# - OC_RELEASE

# All variables (ie OC_TOKEN) that support branch overrides can be overridden by 
# branch specific values (ie OC_TOKEN_DEV=blah, where branch is 'dev'); such vars
# take precedence over the original values.

# Read the branch name from params
BRANCH_NAME=`echo $1 | awk '{print toupper($0)}'`
echo "Running oc-token on branch $BRANCH_NAME"

# Override branch specific vars
function get_branch_var() {
  VAR_NAME=$1
  declare BR_VAR=${VAR_NAME}_${BRANCH_NAME}
  VAR_VALUE=${!BR_VAR}
  # echo "Get Branch var for name: ${VAR_NAME}, value: ${!VAR_NAME}, br_name: ${BR_VAR}, br_value: ${VAR_VALUE}"
  if [[ -z "$VAR_VALUE" ]]; then
    VAR_VALUE=${!VAR_NAME}
    BR_VAR=""
  fi
}

get_branch_var "OC_TOKEN"
OC_TOKEN=${VAR_VALUE}
# Fail if no mandatory vars are missing
if [[ -z "$OC_TOKEN" ]]; then
  echo "Missing OC_TOKEN. Failing."
  exit -1
fi

if [[ -z "$OC_BINARY_FOLDER" && -z "$OC_BINARY_ARCHIVE" ]]; then
  echo "Missing OC_BINARY_FOLDER or OC_BINARY_ARCHIVE. Failing."
  exit -1
fi

get_branch_var "BOT_NAME"
BOT_NAME=${VAR_VALUE}
if [[ -z "$BOT_NAME" ]]; then
  echo "Missing BOT_NAME. Failing."
  exit -1
fi

get_branch_var "OC_PROJECT_NAME"
OC_PROJECT_NAME=${VAR_VALUE}
if [[ -z "$OC_PROJECT_NAME" ]]; then
  export OC_PROJECT_NAME=botfarm
fi
echo "Using Openshift Online project $OC_PROJECT_NAME"

# Define oc defaults
export PROCESS_ARGS=""
if [[ -n "$OC_TEMPLATE_PROCESS_ARGS" ]]; then
  for i in $(echo $OC_TEMPLATE_PROCESS_ARGS | sed "s/,/ /g")
  do
    VAR_NAME=$i
    get_branch_var $i
    export PROCESS_ARGS="$PROCESS_ARGS -p ${i}=${VAR_VALUE}"
  done
  echo "Process args is: ${PROCESS_ARGS}"
fi

if [[ -z "$OC_ENDPOINT" ]]; then
  OC_ENDPOINT="https://api.starter-us-east-1.openshift.com"
fi
if [[ -z "$OC_VERSION" ]]; then
  OC_VERSION=v1.5.1
fi
if [[ -z "$OC_RELEASE" ]]; then
  OC_RELEASE=7b451fc-linux-64bit
fi

OC_FOLDER_NAME=openshift-origin-client-tools-$OC_VERSION-$OC_RELEASE
if [[ "$OC_VERSION" == "v1.4.1" ]]; then
  OC_FOLDER_NAME=openshift-origin-client-tools-$OC_VERSION+$OC_RELEASE
fi

if [[ "$SKIP_OC_INSTALL" != "true" ]]; then
  OC_URL="https://github.com/openshift/origin/releases/download/$OC_VERSION/openshift-origin-client-tools-$OC_VERSION-$OC_RELEASE.tar.gz"
  PATH=$PWD/$OC_FOLDER_NAME:$PATH

  # Download and unpack oc
  curl -Ls $OC_URL | tar xvz
fi

# Log into Openshift Online and use project botfarm
oc login $OC_ENDPOINT --token=$OC_TOKEN ; oc project $OC_PROJECT_NAME
echo "Logged into $OC_ENDPOINT"

get_branch_var "OC_TEMPLATE"
OC_TEMPLATE=${VAR_VALUE}
if [[ -f ".openshift-template.yaml" ]]; then
  export OC_TEMPLATE=".openshift-template.yaml"
  echo "Found $OC_TEMPLATE OpenShift template"
fi

get_branch_var "OC_DELETE_LABEL"
OC_DELETE_LABEL=${VAR_VALUE}
if [[ -n "$OC_DELETE_LABEL" ]]; then
  oc delete all -l $OC_DELETE_LABEL
  echo "Deleted all resources with label $OC_DELETE_LABEL ; ; sleeping 10 secs ..."
  sleep 10
fi

# Create the DeploymentConfig template, if configured
if [[ -n "$OC_TEMPLATE" ]]; then
  oc process -f $OC_TEMPLATE $PROCESS_ARGS | oc create -f -
  echo "$OC_TEMPLATE template created"
fi

# Start the folder build
RESULT=0
if [[ -n "$OC_BINARY_FOLDER" ]]; then
  oc start-build $BOT_NAME --from-dir=$OC_BINARY_FOLDER --wait=true
  RESULT=$?
  echo "Build of $BOT_NAME from folder $OC_BINARY_FOLDER completed"
elif [[ -n "$OC_BINARY_ARCHIVE" ]]; then
  oc start-build $BOT_NAME --from-archive=$OC_BINARY_ARCHIVE --wait=true
  RESULT=$?
  echo "Build of $BOT_NAME from archive $OC_BINARY_ARCHIVE completed"
fi

if [[ $RESULT != 0 ]]; then
  echo "Openshift deployment failed with error code $RESULT, see errors above"
  exit -1
else
  echo "Openshift deployment successful!"
fi
