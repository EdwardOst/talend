#!/usr/bin/env bash

set -euo pipefail

# An example map function, to use in the example below.
map() { local f="$1"; shift; for i in "$@"; do "$f" "$i"; done; }

# Lambda function [λ], passed to the map function.
lambda(){ echo "Lambda sees $1"; }; map lambda *

# Let’s say you have a function with three parameters
# that you want to use as a lambda:
# (As in: Partial function application.)
trio(){ echo "$1 Lambda sees $3 $2"; }

# And there are two values that you want to use to parametrize a
# function that shall be your lambda.
pre="<<<"
post=">>>"

# Then you’d just wrap them in a closure, and be done with it:
lambda(){ trio "$pre" "$post" "$@"; }; map lambda *
