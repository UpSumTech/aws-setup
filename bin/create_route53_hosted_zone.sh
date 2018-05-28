#! /usr/bin/env bash
#########################################################
################# Bash script settings ##################
#########################################################
set -e

#########################################################
################# Variable declaration ##################
#########################################################
AWS_REGION=
DOMAIN_NAME=
SUBDOMAIN_NAME=
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $THIS_DIR/.. && pwd)"
PROJECT_TMPDIR="$(mktemp -d "/tmp/route53.XXXX")"
trap "echo Cleaning up tmp dir; rm -rf "$PROJECT_TMPDIR";" EXIT

#########################################################
################### Helper functions ####################
#########################################################
export PID="$$" # Get parent pid so that you can kill the main proc from subshells
die() {
  echo >&2 "Error : $@"
  kill -s TERM $PID
  exit 1
}

chdir_and_exec() {
  local result
  local fn="$1"
  shift 1
  pushd .
  result=$(eval "$(declare -F "$fn")" "$@")
  popd
  echo "$result"
}

wait_till_done() {
  local fn="$1"
  shift 1
  (eval "$(declare -F "$fn")" "$@") &
  wait
  ok
}

create_subdomain_ns_file() {
  local line
  local ns_servers_file="$1"
  cd "$PROJECT_TMPDIR"
  cp "$ROOT_DIR/templates/subdomain_ns.json" "$PROJECT_TMPDIR/subdomain_ns.json"
  sed -i.bak "s/\$SUBDOMAIN_NAME/$SUBDOMAIN_NAME/g" "$PROJECT_TMPDIR/subdomain_ns.json"
  cat "$PROJECT_TMPDIR/ns_servers" | while read -r line; do
    sed -i.bak "0,/\$NS_SERVER/s//$line/" "$PROJECT_TMPDIR/subdomain_ns.json"
  done
}

#########################################################
################## Public functions #####################
#########################################################
validate() {
  [[ $SUBDOMAIN_NAME =~ $DOMAIN_NAME ]] \
    || die "The domain $DOMAIN_NAME is not contained in the subdomain $SUBDOMAIN_NAME"
}

create_subdomain_hosted_zone() {
  local uuid=$(uuidgen)
  local parent_zone_id="$(aws route53 list-hosted-zones | jq -r ".HostedZones[] | select(.Name==\"$DOMAIN_NAME.\") | .Id")"
  # Create a new hosted zone for the subdomain
  aws route53 create-hosted-zone --name "$SUBDOMAIN_NAME" --caller-reference "$uuid" | jq -r ".DelegationSet.NameServers | .[]" > "$PROJECT_TMPDIR/ns_servers"
  # Add the subdomain NS record to the parent hosted zone
  chdir_and_exec create_subdomain_ns_file "$PROJECT_TMPDIR/ns_servers"
  aws route53 change-resource-record-sets --region "$AWS_REGION" --hosted-zone-id "$parent_zone_id" --change-batch "file://$PROJECT_TMPDIR/subdomain_ns.json"
}

verify() {
  sleep 5
  dig @8.8.8.8 "$SUBDOMAIN_NAME"
}

main() {
  AWS_REGION="$1"
  DOMAIN_NAME="$2"
  SUBDOMAIN_NAME="$3"
  validate
  create_subdomain_hosted_zone
  verify
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
