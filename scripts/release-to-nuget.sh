#!/bin/bash

set -e

# This scripts invokes NuGet command to upload artifacts to nuget.org; it is triggered only on master branch
# Mandatory variables:
# - $CSPROJ (ie src/SymphonyOSS.RestApiClient/SymphonyOSS.RestApiClient.csproj)
#
# Optional variables:
# - $PROPS (ie -Prop Configuration=Release)

if [ "${TRAVIS_BRANCH}" = "master" ]; then
  nuget pack $CSPROJ -IncludeReferencedProjects $PROPS
else
  echo "[Release to NuGet] - skipping, since '${TRAVIS_BRANCH}' is not master"
fi
