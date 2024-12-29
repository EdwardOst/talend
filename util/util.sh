#!/usr/bin/env bash

set -u

[ "${UTIL_FLAG:-0}" -gt 0 ] && return 0

export UTIL_FLAG=1



# read files or here documents into a variable
define(){ IFS=$'\n' read -r -d '' "${1}" || true; }

# returns true if a variable has been declared
# variable may still not be defined if no value has been assigned
declared() {
  local var="${1:?parameter 'var' is required by function 'declared'}"
  [ -n "$(declare -p ${var} 2> /dev/null)" ]
}

# returns true(0) if the variable indirectly named as the parameter is undeclared or undefined
# else returns false (1) if the variable has been defined, including if it has been definted to be the empty string
defined() {
  local var="${1:?parameter 'var' is required by function 'defined'}"
  [ "${!var+defined}" = "defined" ]
}


warningLog() {
    [ -n "${WARNING_LOG:-}" ] && printf "WARNING: %s : %s \n" "${FUNCNAME[*]:1}" "${*}" 1>&2
    return 0
}

infoLog() {
    [ -n "${INFO_LOG:-}" ] && printf "INFO: %s : %s \n" "${FUNCNAME[*]:1}" "${*}" 1>&2
    return 0
}

infoVar() {
    [ -n "${INFO_LOG:-}" ] && printf "INFO: %s : %s=%s \n" "${FUNCNAME[*]:1}" "${1}" "${!1}" 1>&2
    return 0
}

debugLog() {
    [ -n "${DEBUG_LOG:-}" ] && printf "DEBUG: %s : %s \n" "${FUNCNAME[*]:1}" "${*}" 1>&2
    return 0
}

debugVar() {
    [ -n "${DEBUG_LOG:-}" ] && printf "DEBUG: %s : %s=%s \n" "${FUNCNAME[*]:1}" "${1}" "${!1}" 1>&2
    return 0
}

debugStack() {
    if [ -n "${DEBUG_LOG:-}" ] ; then
        local args
        [ "${#}" -gt 0 ] && args="${*}"
        printf "DEBUG: %s : %s \n" "${FUNCNAME[*]:1}" "${args}" 1>&2
    fi
}


errorMessage() {
    printf "ERROR: %s : %s : %s \n" "${0}" "${FUNCNAME[*]:1}" "${*}" 1>&2
}

die() {
    printf "%s : %s : %s \n" "${0}" "${FUNCNAME[*]:1}" "${*}" 1>&2
    exit 111
}

try() {
    while [ -z "${1}" ]; do
        shift
    done
    [ "${#}" -lt 1 ] && die "empty try statement"

    ! "$@" && echo "$0: ${FUNCNAME[*]:1}: cannot execute: ${*}" 1>&2 && exit 111

    return 0
}


assign() {
    local var="${1}"
    local value="${2}"
    required var value
    printf -v "${var}" '%s' "${value}"
}


required() {
    local arg
    local error_message=""
    for arg in "${@}"; do
        if [ -z "${!1+x}" ]; then
            error_message="${error_message} ${arg} undefined"
        elif [ -z "${!arg}" ]; then
            error_message="${error_message} ${arg} empty"
        fi
    done
    [ -n "${error_message}" ] \
        && error_message="missing required arguments:${error_message}" \
        && echo "$0: ${FUNCNAME[*]:1}: ${error_message}" 1>&2 \
        && exit 111
    return 0
}


undefined() {
  local variable="${1:?parmeter 'variable' required for function undefined}"
  if [ "${!variable+x}" == "x" ]; then
    return 1
  else
    return 0
  fi
}


repeat() {
  local targetvar="${1:?parameter 'targetvar' required for function repeat}"
  local char="${2:?parameter 'char' required for function repeat}"
  local n="${3:?parameter 'n' required for function repeat}"
  local cmd="printf -v ${targetvar} -- '${char}%.0s' {1..${n}}"
  eval "${cmd}"
}

# usage <some_command> | indent 2 4
# would add 2 levels of indentation each being 4 characters
indent() {
  local indent_level="${1:-1}"
  local indent_size="${2:-2}"
  pr -to $(( indent_level * indent_size ))
}


# lazy load code with a here document.  backslash escaped variable references will not be loaded until lazy is invoked.
lazy() {
  local code="${1}"
  eval "source /dev/stdin <<< \"${code}\""
}

trap_add() {
    if [ "${1}" = "-h" ] || [ "${1}" = "--help" ] || [ "${#}" -lt 2 ] ; then
        cat <<-HELPDOC
	  DESCRIPTION

	  USAGE
	    trap_add <handler> <signal>

	    parameter: handler: a command or usually a function used as a signal handler
            parameter: signal: one or more trappable SIGNALS to which the handler will be attached
	HELPDOC
        return 2
    fi

    local trap_command="${1}"
    shift 1
    local trap_signal
    for trap_signal in "$@"; do
        debugVar trap_signal

        # Get the currently defined traps
        local existing_trap
        local current_trap
        current_trap=$(trap -p "${trap_signal}")
        debugLog "current trap: ${current_trap}"
        existing_trap=$( trap -p "${trap_signal}" | awk -F"'" '{ print $2 }' )
        debugVar existing_trap

        # Remove single apostrophe formatting wrapper
        existing_trap="${existing_trap#\'}"
        existing_trap="${existing_trap%\'}"
        debugVar existing_trap

        # Append new trap to old trap
        [ -n "${existing_trap}" ] && existing_trap="${existing_trap};"
        local new_trap="${existing_trap}${trap_command}"
        debugVar new_trap

        # Assign the composed trap
        # shellcheck disable=SC2064
        trap "${new_trap}" "${trap_signal}"
    done
}

# set the trace attribute for the above function.  this is
# required to modify DEBUG or RETURN traps because functions don't
# inherit them unless the trace attribute is set
declare -f -t trap_add

debugLog "sourced: util.sh"
