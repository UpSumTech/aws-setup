#!/bin/bash
set -e

#########################################################
################### Helper functions ####################
#########################################################
export PID="$$" # Get parent pid so that you can kill the main proc from subshells
err() {
  echo >&2 "Error : $@"
  kill -s TERM $PID
  exit 1
}

upgrade_pip() {
  pip install --upgrade pip
}

#########################################################
################### Helper functions ####################
#########################################################
setup_pyenv() {
  upgrade_pip
  curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
  echo 'export PATH="/home/ubuntu/.pyenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc
  echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
  exec $SHELL
}

setup_autoenv() {
  pip install autoenv
  pip install credstash
  echo "source `which activate.sh`" >> ~/.bashrc
  exec $SHELL
}

main() {
  setup_pyenv
  setup_autoenv
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
