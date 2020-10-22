#!/bin/bash

# This script submits metrics to WhiteSource Software (WSS) for Maven projects hosted in GitHub.
# It accepts a GitHub org and repository name as input, and excepts an environment
# variable called WSS_API_KEY to connect with WSS servers.

# How to run: ./wss-maven-scan.sh <org name> <repo name>
# Example: ./wss-maven-scan.sh rh-mercury product-eligibility-DMN

ORG_NAME=$1
PROJECT_NAME=$2

if [ -z "$WSS_API_KEY" ]; then
  echo "Missing $WSS_API_KEY environment variable; exiting."
  exit -1
fi

if [ ! -f /tmp/wss-unified-agent.jar ]; then
  cd /tmp
  curl -LJO https://github.com/whitesource/unified-agent-distribution/releases/latest/download/wss-unified-agent.jar
  cd -
fi

# Checkout the GitHub repository
if [ ! -d "$PROJECT_NAME" ]; then
  git clone git@github.com:$ORG_NAME/$PROJECT_NAME.git
fi
cd $PROJECT_NAME

# Configure the Agent
rm -rf wss-unified-agent.config
curl -LJO https://github.com/whitesource/unified-agent-distribution/raw/master/standAlone/wss-unified-agent.config
sed -i.bak "s/apiKey=/apiKey=$WSS_API_KEY/g" wss-unified-agent.config
sed -i.bak "s/projectName=/projectName=$PROJECT_NAME/g" wss-unified-agent.config

# Configure Maven build
sed -i.bak '/includes=/d' wss-unified-agent.config
sed -i.bak "s/\#maven.resolveDependencies=false/maven.resolveDependencies=true/g" wss-unified-agent.config
sed -i.bak "s/\#maven.runPreStep=false/maven.runPreStep=true/g" wss-unified-agent.config
echo "includes=**/*jar" >> wss-unified-agent.config

rm -rf wss-unified-agent.config.bak

# Inovke the unified agent
java -jar /tmp/wss-unified-agent.jar -c wss-unified-agent.config

# Remove config file
rm -rf wss-unified-agent.config
