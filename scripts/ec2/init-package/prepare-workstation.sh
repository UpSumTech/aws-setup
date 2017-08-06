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
  curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
  echo 'export PATH="/home/ubuntu/.pyenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc
  echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
  exec $SHELL
}

setup_autoenv() {
  pip install autoenv
  echo "source `which activate.sh`" >> ~/.bashrc
  exec $SHELL
}

setup_ssh_keys_and_tokens() {
  ssh-keygen -t rsa -N "" -b 4096 -C "ssh private key" -f id_rsa
  touch ~/.ssh/authorized_keys
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/id_rsa
  # pip install credstash
  # credstash -r us-west-2 -t kms-cred-stash get -n id_rsa.pub type=public > ~/.ssh/id_rsa.pub
  # credstash -r us-west-2 -t kms-cred-stash get -n id_rsa type=private > ~/.ssh/id_rsa
  # chmod 600 ~/.ssh/id_rsa
  # chmod 600 ~/.ssh/id_rsa.pub
  # credstash -r us-west-2 -t kms-cred-stash get -n github_pac_token | xargs -n 1 -I % echo 'export GITHUB_REPO_PERSONAL_ACCESS_TOKEN=%' >> "$HOME/.bashrc"
  exec $SHELL
}

setup_workstation() {
  pushd .
  git clone https://github.com/sumanmukherjee03/workstation.git
  cd ~/workstation
  make build HOST_IP=localhost DRY_RUN=off
  popd
}

main() {
  setup_pyenv
  setup_autoenv
  setup_ssh_keys_and_tokens
  setup_workstation
}

[[ "$BASH_SOURCE" == "$0" ]] && main "$@"
