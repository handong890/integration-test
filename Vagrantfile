VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


  config.vm.box = "elastic/ubuntu-14.04-x86_64"

  config.vm.network :forwarded_port, guest:5601, host:5601
  config.vm.network :forwarded_port, guest:9200, host:9200

   config.vm.provision "shell", path: "qa/integration5.0snapshot.sh"

  config.vm.provider :virtualbox do |vb|
    vb.memory = 6144
    vb.cpus = 4
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate//vagrant","1"]
  end

end
