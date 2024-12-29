#!/usr/bin/env bash

set -euo pipefail
# set -x

source ../array-util.sh

function oper() {
    echo $1
}


forline test-forline.txt oper
