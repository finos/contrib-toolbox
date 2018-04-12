#!/bin/bash

# inject-vars.sh - pass a list environment variables and a file input you want to inject with var values; the script will replace placeholders with variable values and generate a new file.
# Input files can define placeholders with the variable names in <<double diamonds notation>>

# Example:
#   cat input.txt
#   > hi <<NAME>>, today is <<WEATHER>> in <<LOCATION>>
#   export NAME=maoo
#   export WEATHER=warm
#   export LOCATION=Barcelona
#   inject-vars.sh input.txt output.txt
#   cat output.txt
#   > hi maoo, today is warm in Barcelona

FILE_INPUT=$1
FILE_OUTPUT=$2

if [[ -z $FILE_INPUT || -z $FILE_OUTPUT ]]; then
  echo "Cannot read parameters"
  echo "Usage: inject-vars.sh input.txt output.txt"
  exit -1
else
  cp -f $FILE_INPUT $FILE_OUTPUT
  while IFS='=' read -r VAR_NAME VAR_VALUE ; do
    grep -q "<<${VAR_NAME}>>" $FILE_OUTPUT
    if [ $? ]; then
      sed "s%<<${VAR_NAME}>>%${VAR_VALUE}%g" $FILE_OUTPUT > $FILE_OUTPUT.tmp
      if [ -s "$FILE_OUTPUT.tmp" ]; then
        mv $FILE_OUTPUT.tmp $FILE_OUTPUT
        echo "Replaced value for placeholder <<>${VAR_NAME}>"
      fi
    fi
  done < <(env)

fi
