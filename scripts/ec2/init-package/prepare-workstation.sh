#!/usr/bin/env bash

set -ex

#########################################################
################### Helper functions ####################
#########################################################
export PID="$$" # Get parent pid so that you can kill the main proc from subshells
err() {
  echo >&2 "Error : $@"
  kill -s TERM $PID
  exit 1
}

#########################################################
################### Helper functions ####################
#########################################################
setup_pyenv() {
  if test ! -d $HOME/.pyenv && cat $HOME/.bashrc | grep -i 'pyenv'; then
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.bashrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.bashrc
    echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc
    pip install virtualenv virtualenvwrapper
    git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
    echo 'eval "$(pyenv virtualenv-init -)"' >> $HOME/.bashrc
  fi
  . $HOME/.bashrc
}

setup_ssh_keys_and_tokens() {
  if [[ ! -f $HOME/.ssh/id_rsa && ! -f $HOME/.ssh/id_rsa.pub && ! -f $HOME/.ssh/authorized_keys ]]; then
    ssh-keygen -t rsa -N "" -b 4096 -C "ssh private key" -f $HOME/.ssh/id_rsa
    chmod 600 $HOME/.ssh/id_rsa
    chmod 600 $HOME/.ssh/id_rsa.pub
    touch $HOME/.ssh/authorized_keys
    cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
    chmod 600 $HOME/.ssh/authorized_keys
  fi
  ssh-keyscan -H localhost >> $HOME/.ssh/known_hosts
  echo "Updated ssh"
}

setup_workstation() {
  pushd .
  . $HOME/.bashrc
  cd $HOME
  [[ -d $HOME/workstation ]] && rm -rf $HOME/workstation
  git clone https://github.com/sumanmukherjee03/workstation.git $HOME/workstation
  cd workstation
  . .env
  make build HOST_IP=localhost DRY_RUN=off
  popd
}

main() {
  setup_pyenv
  setup_ssh_keys_and_tokens
  setup_workstation
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
