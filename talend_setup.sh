#!/usr/bin/env bash

talend_script_path=$(readlink -e "${BASH_SOURCE[0]}")
talend_script_dir="${talend_script_path%/*}"

# shellcheck source=talend_config.sh
source "${talend_script_dir}/talend_config.sh"

# shellcheck source=util/util.sh
source "${talend_script_dir}/util/util.sh"

talend_setup() {

  talend_setup_volume
  talend_setup_worker_image
  talend_setup_worker_container
  talend_setup_download
  talend_setup_load

  infoLog "Cleaning up worker container '${talend_worker_container}'"
  docker rm "${talend_worker_container}"

  infoLog "Cleaning up worker image '${talend_worker_image}'"
  docker rmi "${talend_worker_image}"

  if [ $# -gt 0 ]; then
    case $1 in
      clean | tac | nexus | jobserver | runtime)
        set -- talend_"$1" "${@:2}"
      ;;
    esac
  fi

  "$@"
}


talend_clean() {


  infoLog "Cleaning up worker container '${talend_worker_container}'"
  docker rm "${talend_worker_container}"

  infoLog "Cleaning up talend volune '${talend_volume}'"
  docker volume rm "${talend_volume}"

  infoLog "Cleaning up worker image '${talend_worker_image}'"
  docker rmi "${talend_worker_image}"

  if [ $# -gt 0 ]; then
    case $1 in
      setup | tac | nexus | jobserver | runtime)
        set -- talend_"$1" "${@:2}"
      ;;
    esac
  fi

  "$@"

}


talend_setup_volume() {

  infoLog "Setting up talend volume '${talend_volume}'"
  docker volume create "${talend_volume}"

}


talend_setup_worker_image() {

  infoLog "Setting up worker image '${talend_worker_image}'"
  docker build -t "${talend_worker_image}" .

}


talend_setup_worker_container() {

  infoLog "Setting up worker container '${talend_worker_container}'"
  docker container create --name "${talend_worker_container}" -v "${talend_volume}":/dest "${talend_worker_image}"

}


talend_setup_download() {

  # shellcheck disable=SC2034
  { IFS="=" read -r property_name talend_user; IFS="=" read -r property_name talend_password; } < talend.credentials

  infoLog "Downloading Talend install files to '${talend_target_dir}'"
  wget -q -nv -i talend.manifest -P "${talend_target_dir}"  --http-user="${talend_user}" --http-password="${talend_password}"

}


talend_setup_load() {

  infoLog "Loading Talend install files to Docker volume '${talend_volume}'"
  tar -cv -C "${talend_target_dir}" .  | docker cp - "${talend_worker_container}":/dest

}
