
Vagrant.configure(2) do |config|
  config.ssh.forward_agent = true

  config.vm.box = "centos/7"
  config.vm.box_version = "1804.02"
  config.vm.provision :shell, { path: "vagrant/bootstrap_root.sh" }
  config.vm.provision :shell, { path: "vagrant/bootstrap_user.sh", privileged: false, args: [ENV["USER"]] }
  config.vm.provision :shell, { path: "vagrant/startup.sh", privileged: false, run: "always" }
  config.vm.network :forwarded_port, { host: 3000, guest: 3000, auto_correct: true }
  config.vm.network :forwarded_port, { host: 8808, guest: 8808, auto_correct: true }
end
