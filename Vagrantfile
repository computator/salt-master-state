Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.provider "virtualbox" do |v|
    v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end

  config.vm.synced_folder ".", "/root/salt/salt-master"

  config.vm.provision "states", type: "shell", inline: <<-SHELL
    mkdir -p /root/salt/mercurial && curl -sL https://github.com/rlifshay/salt-mercurial-state/archive/master.tar.gz | tar -zxvf - --strip-components 1 -C /root/salt/mercurial
  SHELL

  config.vm.provision "salt", install_master: true
  config.vm.provision "install", type: "shell", keep_color: true, inline: "salt-call --force-color --local --file-root /root/salt --state-output changes state.apply salt-master.managed"
end