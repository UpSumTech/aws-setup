#!/usr/bin/env bash

CURRENT_STATE_LOG_FILE=/var/log/current-state.log

ok() {
  echo -n ''
}

log_user_and_group() {
  echo;echo;echo ">>>>>>>>>>>>>>> USER AND GROUP INFO <<<<<<<<<<<<<"
  echo "User id : $(id -u)"
  echo "Group id : $(id -g)"
  echo "User name : $(id -un)"
  echo "Group name : $(id -gn)"
  ok
}

log_env_vars() {
  echo;echo;echo ">>>>>>>>>>>>>>> ENV VAR INFO <<<<<<<<<<<<<"
  printenv
  ok
}

log_current_dir_content() {
  echo;echo;echo ">>>>>>>>>>>>>>> CWD INFO <<<<<<<<<<<<<"
  echo "Current Dir : $(pwd)"
  ls -lah
  ok
}

is_current_user_root() {
  if [[ "$(id -u)" == "0" ]]; then
    echo "User root : yes"
  else
    echo "User root: no"
  fi
}

log_disk_usage() {
  echo;echo;echo ">>>>>>>>>>>>>>> DISK USAGE INFO <<<<<<<<<<<<<"
  df -kh | grep -i -v 'filesystem' | awk '{print $1 ":" $5}'
  ok
}

log_os_info() {
  echo;echo;echo ">>>>>>>>>>>>>>> OS INFO <<<<<<<<<<<<<"
  cat /etc/*-release
  uname -a
  ok
}

log_selinux_info() {
  echo;echo;echo ">>>>>>>>>>>>>>> SELINUX INFO <<<<<<<<<<<<<"
  command -v getenforce >/dev/null 2>&1 \
    && getenforce
  ok
}

log_ip_tables_info() {
  echo;echo;echo ">>>>>>>>>>>>>>> SELINUX INFO <<<<<<<<<<<<<"
  command -v iptables >/dev/null 2>&1 \
    && iptables -nvL \
    && iptables -nvL -t filter \
    && iptables -nvL -t nat
  ok
}

log_installed_packages() {
  echo;echo;echo ">>>>>>>>>>>>>>> PACKAGE INFO <<<<<<<<<<<<<"
  command -v rpm >/dev/null 2>&1 && rpm -qa
  command -v dpkg >/dev/null 2>&1 && dpkg --list
  ok
}

main() {
  touch $CURRENT_STATE_LOG_FILE
  log_user_and_group >> $CURRENT_STATE_LOG_FILE
  log_env_vars >> $CURRENT_STATE_LOG_FILE
  log_current_dir_content >> $CURRENT_STATE_LOG_FILE
  is_current_user_root >> $CURRENT_STATE_LOG_FILE
  log_disk_usage >> $CURRENT_STATE_LOG_FILE
  log_os_info >> $CURRENT_STATE_LOG_FILE
  log_selinux_info >> $CURRENT_STATE_LOG_FILE
  log_ip_tables_info >> $CURRENT_STATE_LOG_FILE
  log_installed_packages >> $CURRENT_STATE_LOG_FILE
  ok
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
