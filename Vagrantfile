# -*- mode: ruby -*-
# vi: set ft=ruby :

# This is a amazon linux like test box with RHEL and t2.medium cpu and mem provisioned
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "mrlesmithjr/rhel-7"

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define "rhel" do |rhel|
    rhel.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end
    rhel.vm.hostname = "rhel.dev"
    rhel.vm.network "private_network", ip: "10.40.50.70"
  end
end
