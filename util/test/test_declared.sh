#!/usr/bin/env bash

set -e

source ../util.sh

test_declared() {
  local var="${1:?parameter 'var' is required for function 'test_declared'}"
  if declared "${var}"; then
    echo "${var} is declared"
  else
    echo "${var} is not declared"
  fi
}

test_declared undeclared_var

declare declared_var
test_declared declared_var

declare empty_var=""
test_declared empty_var

declare defined_var=hello
test_declared defined_var
