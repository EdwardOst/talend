#!/usr/bin/env bash

[ "${SCOPE_CONTEXT_FLAG:-0}" -gt 0 ] && return 0

set -u

export SCOPE_CONTEXT_FLAG=1

scope_context_script_path=$(readlink -e "${BASH_SOURCE[0]}")
scope_context_script_dir="${scope_context_script_path%/*}"

scope_context_util_path=$(readlink -e "${scope_context_script_dir}/util.sh")
# shellcheck source=util.sh
source "${scope_context_util_path}"

scope_context_array_path=$(readlink -e "${scope_context_script_dir}/array-util.sh")
# shellcheck source=array-util.sh
source "${scope_context_array_path}"

# read/write property files to dictionaries
# load/export dictionaries to local variables
#
# dictionaries are (key,value) associative arrays
# contexts are just dictionaries following naming conventions to prefix variables baesd on the name of the function in which they occur (to avoid namespace collisions)
#
# load_dictionary - load dictionary into variables
# load_context - load context into variables
# export_dictionary - write variables to dictionary
# export_context - write variables to context
#
# read_dictionary - read properties file into dictionary
# read_context - read properties file into context
# write_dictionary - write dictionary to properties file
# write_context - write context to properties file


# echo variables with a given prefix
#
# usage: echo_scope [ prefix [separator]]
#
function echo_scope() {
  local prefix="${1:-${FUNCNAME[1]}}"
  local separator="${2:-_}"

  prefix="${prefix}${separator}"

  printf "CONTEXT: %s:\n" "${prefix}"
  local cmd="declare -p \${!${prefix}*}"
  eval "${cmd}" | indent 1 2

}


# read associative array into variables adding an optional prefix
# add/remove a prefix by starting prefix with +/-
#
# usage: load_dictionary <context_array> [prefix [separator]]
#
function load_dictionary() {
    [ "${#}" -lt 1 ] && echo "usage: load_dictionary <context_array> [prefix [separator]]" && exit 1

    local -r -n context_array="${1}"
    local prefix="${2}"
    local operator

    if [ -n "${prefix}" ]; then
        local separator="${3:-_}"
        prefix="${prefix}${separator}"
        if [ "${prefix:0,1}" == "-" ]; then
            prefix="${prefix:1}"
            operator="remove_prefix"
        else
            if [ "${prefix:0,1}" == "+" ]; then
                prefix="${prefix:1}"
            fi
            operator="add_prefix"
        fi
    fi

    local property
    for key in "${!context_array[@]}"; do
        property="${key}"
        debugVar "property"
        [ -n "${operator}" ] && "${operator}" "property" "${prefix}"
        assign "${property}" "${context_array[${key}]}"
        debugVar "${property}"
    done
}


# load context scope into variables
# context scope does not have a prefix but variables do (in order to avoid namespace collisions)
#
# usage:
#     load_context [context_array]
#
function load_context() {
    local context_array="${1:-${FUNCNAME[1]}_context}"

    load_dictionary "${context_array}" "${FUNCNAME[1]}"
}


# write all variables starting with a prefix to an associative array
# removing the prefix from the key in the process
#
function export_dictionary() {
  [ "${#}" -lt 2 ] && echo "usage: export_dictionary <context_array_ref> <prefix> [ <separator> ]" && exit 1

  local -n context_array="${1}"
  local prefix="${2}"
  local separator="${3:-_}"

  prefix="${prefix}${separator}"

  local list_params
  define list_params <<__EOF__
    local -a var_array=( \${!${prefix}*} )
__EOF__
  eval "${list_params}"

  local key
  for var_name in "${var_array[@]}"; do
      key="${var_name}"
      remove_prefix "key" "${prefix}"
      context_array["${key}"]="${!var_name}"
  done
}


# export variables to context
# context name is calling function appended with _context
# prefix is the calling function
#
# usage:
#     export_context
#
function export_context() {
    export_dictionary "${FUNCNAME[1]}_context" "${FUNCNAME[1]}"
}


# utility function used by read_dictionary to parse a line from a property file into an
# associative array, applying an operator to transform the key
#
function parse_property_file() {
    [ "${#}" -lt 4 ] && echo "usage: parse_property_file <property_key_value_string> <properties_array> <operator> <prefix>" && exit 1
    local -r line="${1}"
    local -r -n properties_arr="${2}"
    local -r operator="${3:-}"
    local -r prefix="${4:-}"

    local key="${line%%=*}"
    [ -n "${operator}" ] && [ -n "${prefix}" ] && "${operator}" "key" "${prefix}"

    local value="${line##*=}"

    debugLog "${!properties_arr}[${key}]=${value}"
    properties_arr["${key}"]="${value}"
}


# read a property file into an associative array
# optionally add/remove a prefix by starting prefix with +/-
#
function read_dictionary() {
    [ "${#}" -lt 2 ] && echo "usage: read_dictionary <properties_file> <properties_array> [prefix [separator]]" && exit 1
    local -r properties_file="${1}"
    # shellcheck disable=SC2178
    local -r properties_arr="${2}"
    local prefix="${3:-}"
    local separator="${4:-_}"
    local operator=""

    mapfile -t < <(grep -v "#" "${properties_file}")

    if [ -n "${prefix}" ]; then
        prefix="${prefix}${separator}"
        if [ "${prefix:0,1}" == "-" ]; then
            prefix="${prefix:1}"
            operator="remove_prefix"
        else
            if [ "${prefix:0,1}" == "+" ]; then
                prefix="${prefix:1}"
            fi
            operator="add_prefix"
        fi
    fi

    # shellcheck disable=SC2128
    foreach MAPFILE parse_property_file "${properties_arr}" "${operator}" "${prefix}"
}


# read property file into context,
# context name is the name of the calling function appended with _context
# property file defaults to context name
# by default neither properties nor context keys have prefixes
#
function read_context() {
    local -r properties_file="${1:-${FUNCNAME[1]}.properties}"

    debugLog "read_dictionary ${properties_file} ${FUNCNAME[1]}_context"
    read_dictionary "${properties_file}" "${FUNCNAME[1]}_context"
}


# write associative array to property file
# optionally add/remove a prefix by starting prefix with +/-
#
# usage
#     write_dictionary <properties_array> <properties_file> [prefix [separator]]
#
function write_dictionary() {
    [ "${#}" -lt 2 ] && echo "usage: write_dictionary <properties_array> <properties_file> [prefix [separator]]" && exit 1

    # shellcheck disable=SC2178
    local -r -n properties_arr="${1}"
    local -r properties_file="${2}"
    local prefix="${3:-}"
    local separator="${4:-_}"
    local operator=""

    if [ -n "${prefix}" ]; then
        prefix="${prefix}${separator}"
        if [ "${prefix:0,1}" == "-" ]; then
            prefix="${prefix:1}"
            operator="remove_prefix"
        else
            if [ "${prefix:0,1}" == "+" ]; then
                prefix="${prefix:1}"
            fi
            operator="add_prefix"
        fi
    fi

    local property
    for key in "${!properties_arr[@]}"; do
        property="${key}"
        [ -n "${operator}" ] && "${operator}" "property" "${prefix}"
        echo "${property}=${properties_arr[${key}]}"
    done > "${properties_file}"
}


# write context to property file
# context name is the name of the calling function
# strip the prefix from each key before writing
# the prefix is the context name
# property file defaults to context name
# by default neither properties nor context keys have a prefix
#
# usage:
#     write_context [properties_array [properties_file]]
#
function write_context() {
    local properties_array="${1:-${FUNCNAME[1]}_context}"
    local -r properties_file="${2:-${FUNCNAME[1]}.properties}"

    write_dictionary "${properties_array}" "${properties_file}"
}


function remove_prefix() {
  [ "${#}" -lt 2 ] && echo "usage: remove_prefix <root> <prefix>" && exit 1
  local -n root="${1}"
  local -r prefix="${2}"
  # shellcheck disable=SC2295
  assign root "${root#${prefix}}"
}


function add_prefix() {
    [ "${#}" -lt 2 ] && echo "usage: add_prefix <root> <prefix>" && exit 1
    local -n root="${1}"
    local -r prefix="${2}"
    assign root "${prefix}${root}"
}


export -f echo_scope
export -f load_dictionary
export -f load_context
export -f export_dictionary
export -f export_context
export -f parse_property_file
export -f read_dictionary
export -f read_context
export -f write_dictionary
export -f write_context
export -f remove_prefix
export -f add_prefix

debugLog "sourced: scope-context.sh"
