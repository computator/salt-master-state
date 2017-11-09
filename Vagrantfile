Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.provider "virtualbox" do |v|
    v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end

  config.vm.synced_folder ".", "/root/salt/salt-master"
  config.vm.provision "salt", install_master: true
  config.vm.provision "install", type: "shell", keep_color: true, inline: "salt-call --force-color --local --file-root /root/salt --state-output changes state.apply salt-master"
end