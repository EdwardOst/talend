#!/usr/bin/env bash

talend_script_path=$(readlink -e "${BASH_SOURCE[0]}")
# shellcheck disable=SC2034
talend_script_dir="${talend_script_path%/*}"


# initialze all shell variables as local to a containing function
# and then chain subsequent function calls

talend_config() {


  local -r talend_target_dir="${talend_target_dir:-download}"

  local -r talend_volume="${talend_volume:-talend}"
  local -r talend_worker_image="${talend_worker_image:-talend_worker_image}"
  local -r talend_worker_container="${talend_worker_container:-talend_worker}"

  local -r talend_version="${talend_version:-8.0.1}"
  local -r talend_network="${talend_network:-talend-network}"

  local -r talend_tac_host_port="${talend_tac_host_port:-8080}"
  local -r talend_tac_container_port="${talend_tac_container_port:-8080}"
  local -r talend_tac_container_name="${talend_tac_container_name:-tac}"

  # These shell variables in the host OS are mapped to environment variables in the docker image.
  # The shell variables have the same name as the environment variables but are lowercase.

  # TALEND_ROOT_PASSWORD
  # This variable is mandatory and specifies the password that will be set for the talend root superuser account.
  local -r talend_root_password="${talend_root_password:-tadmin}"

  # TALEND_TAC_DATABASE
  # The TALEND_TAC_USER  will be granted superuser access (corresponding to GRANT ALL) to this database.
  local -r talend_tac_database="${talend_tac_database:-tac}"

  # TALEND_TAC_USER, TALEND_TAC_PASSWORD
  # These variables are optional, used in conjunction to create a new user and to set that user's password.
  # This user will be granted superuser permissions (see above) for the database specified by the TAC_DATABASE variable.
  # Both variables are required for a user to be created.
  local -r talend_tac_user="${talend_tac_user:-talend}"
  local -r talend_tac_password="${talend_tac_password:-talend123}"

  # get the ip address of the talend container
  # not necessary if using a docker network
  # talend_IP=$(docker inspect -f "{{.NetworkSettings.Networks.${talend_network}.IPAddress}}" "${talend_container_name}")

  if [ $# -gt 0 ]; then
    case $1 in
      clean | setup | tac | nexus | jobserver | runtime)
        set -- talend_"$1" "${@:2}"
      ;;
    esac
  fi

  "$@"

}


talend() {

  if [ $# -gt 0 ] && [ "config" = "${1}" ]; then
    shift 1
  fi
  talend_config "${@}"

}
