#!/usr/bin/env bash

set -euo pipefail
#set -x

source ../array-util.sh


declare -a mycommand=
declare -a oldcommand=( a b c )
init_array "mycommand" "${oldcommand[@]}"

echo "mycommand=${mycommand[@]}"
