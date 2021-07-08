#!/bin/bash

# change to scripts directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${SCRIPT_DIR}

# get yesterday's date
DATE=`date -d "yesterday" "+%Y-%m-%d"`

./analysis.R ${DATE}