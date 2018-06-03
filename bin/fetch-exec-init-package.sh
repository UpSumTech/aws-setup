#!/usr/bin/env bash
#########################################################
################# Bash script settings ##################
#########################################################
set -e

#########################################################
######################### Vars ##########################
#########################################################
TMPDIR="$(mktemp -d "/tmp/ec2-init-scripts.XXXXXXX")"
trap "echo Cleaning up tmp dir; rm -rf "$TMPDIR";" EXIT

INIT_FILES=( \
  "harden-os.sh" \
  "prepare-workstation.sh",
  "get-os-info.sh" \
  "get-initd-scripts.sh" \
  "prepare-nginx.sh" \
)
S3_INIT_SCRIPTS_BUCKET=
S3_INIT_PACKAGE_VERSION=
INIT_PACKAGE_NAME="ec2setup"
INIT_PACKAGE_FILE_NAME="${INIT_PACKAGE_NAME}.zip"

#########################################################
################### Helper functions ####################
#########################################################
export PID="$$" # Get parent pid so that you can kill the main proc from subshells
die() {
  echo >&2 "Error : $@"
  kill -s TERM $PID
  exit 1
}

get_s3_package_path() {
  echo "s3://${S3_INIT_SCRIPTS_BUCKET}/${S3_INIT_PACKAGE_VERSION}/${INIT_PACKAGE_FILE_NAME}"
}

get_init_package() {
  local s3_path="$(get_s3_package_path)"
  aws s3 cp "$s3_path" .
  unzip "$INIT_PACKAGE_FILE_NAME" -d "${INIT_PACKAGE_NAME}"
  rm "${INIT_PACKAGE_FILE_NAME}"
}

#########################################################
################# Higer level functions #################
#########################################################
help() {
  echo " The valid options of this file are
  -b <bucket_name> : The bucket name containing the init scripts
  -v <version> : The version of scripts to execute
  Example : ./fetch-exec-init-package.sh -b ec2-init-scripts -v v0.0.1
  "
}

validate() {
  command -v aws \
    || die "The aws cli is not installed on this ec2 box"

  [[ ! -z "$S3_INIT_SCRIPTS_BUCKET" && ! -z "$S3_INIT_PACKAGE_VERSION" ]] \
    || die "The script was called with out the required options"

  local s3_path="$(get_s3_package_path)"
  aws s3 ls "$s3_path" \
    || die "The init package version you are looking for does not exist"

  get_init_package
  local file
  for file in ${INIT_PACKAGE_NAME}/*; do
    [[ "${INIT_FILES[@]}" =~ "$(basename "$file")" ]] \
      || die "$file does not exist in the init package downloaded from S3"
  done
}

exec_init_scripts() {
  local file
  for file in $INIT_PACKAGE_NAME/*; do
    /usr/bin/env bash $file
  done
}

#########################################################
###################### Entrypoint #######################
#########################################################
main() {
  local option

  while getopts “h:b:v:” option; do
    case $option in
      b)
        S3_INIT_SCRIPTS_BUCKET="${OPTARG}"
        ;;
      v)
        S3_INIT_PACKAGE_VERSION="${OPTARG}"
        ;;
      *)
        help
    esac
  done

  pushd .
  cd "$TMPDIR"
  validate
  exec_init_scripts
  popd
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
