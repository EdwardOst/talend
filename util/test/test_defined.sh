#!/usr/bin/env bash

source ../util.sh

set -u

declare declared_var
declare empty_var=""
declare initialized_var=hello

test_defined() {
  local var="${1:?parameter 'var' required by function 'test_undefined'}"
  if defined "${var}"; then
    echo "${var} is defined"
  else
    echo "${var} is undefined"
  fi
}

test_defined undeclared_var

test_defined declared_var

test_defined empty_var

test_defined initialized_var

if defined; then
  echo "check error handling when no parameter is passed to undefined (true)"
else
  echo "check error handling when no parameter is passed to undefined (false)"
fi

