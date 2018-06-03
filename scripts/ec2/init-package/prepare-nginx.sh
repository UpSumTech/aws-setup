#!/usr/bin/env bash

set -x

#########################################################
###################### Variables ########################
#########################################################

NGINX_INSTALL_LOG_FILE=/var/log/nginx-install.log

#########################################################
################### Helper functions ####################
#########################################################
export PID="$$" # Get parent pid so that you can kill the main proc from subshells
err() {
  echo >&2 "Error : $@"
  kill -s TERM $PID
  exit 1
}

ok() {
  echo -n ''
}

#########################################################
################### Helper functions ####################
#########################################################
clean() {
  apt-get purge \
    nginx \
    nginx-full \
    nginx-light \
    nginx-naxsi \
    nginx-common \
    || ok
  rm -rf /etc/nginx >/dev/null 2>&1 || ok
  local existing_web_server_pid="$(netstat -4 -anp --tcp | grep ':80' | grep -i 'LISTEN' | awk '{print $7}' | cut -d '/' -f1)"
  [[ ! -z $existing_web_server_pid ]] && kill -TERM $existing_web_server_pid || ok
}

install() {
  apt-get install -y nginx
  ok
}

update_conf() {
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.original.conf
  cp nginx.conf /etc/nginx/nginx.conf
  ok
}

main() {
  clean
  install
  update_conf
  nginx -t && service nginx restart
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
