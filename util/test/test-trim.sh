#!/usr/bin/env bash

set -euo pipefail
#set -x

source ../string-util.sh

myvar="   hello world   "
trim myvar
echo "|${myvar}|"
