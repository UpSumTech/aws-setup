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

#########################################################
################### Helper functions ####################
#########################################################
setup_pyenv() {
  [[ -d ~/.pyenv ]] && rm -rf ~/.pyenv
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
  echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc
  pip install virtualenv virtualenvwrapper
  git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
  echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
  . ~/.bashrc
}

upgrade_pip_packages() {
  pip install -U botocore
}

setup_ssh_keys_and_tokens() {
  if [[ ! -f ~/.ssh/id_rsa && ! -f ~/.ssh/id_rsa.pub ]]; then
    ssh-keygen -t rsa -N "" -b 4096 -C "ssh private key" -f ~/.ssh/id_rsa
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa.pub
  fi
  cat ~/.ssh/authorized_keys | grep "$(cat ~/.ssh/authorized_keys)" \
    || cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  echo "Updated ssh"
}

setup_workstation() {
  pushd .
  . ~/.bashrc
  cd ~
  [[ -d ~/workstation ]] && rm -rf ~/workstation
  git clone https://github.com/sumanmukherjee03/workstation.git ~/workstation
  cd workstation
  make build HOST_IP=localhost DRY_RUN=off
  popd
}

setup_autoenv() {
  pip install autoenv
  echo "source `which activate.sh`" >> ~/.bashrc
}

main() {
  setup_pyenv
  upgrade_pip_packages
  setup_ssh_keys_and_tokens
  setup_workstation
  setup_autoenv # Install as root for now and then worry about autoenv. It creates problems.
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
