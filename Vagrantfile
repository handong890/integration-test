VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


#  config.vm.box = "boxcutter/ubuntu1604-desktop"
  config.vm.box = "ubuntu/trusty64"
  config.vm.box_url = 'https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box'
#  config.vm.box = "elastic/ubuntu-16.04-x86_64"
  
  
  
#  config.vm.network :forwarded_port, guest:4444, host:4444
  config.vm.network :forwarded_port, guest:5601, host:5620
  config.vm.network :forwarded_port, guest:9200, host:9220
#  config.vm.network :private_network, ip: "192.168.33.10"

   config.vm.provision "shell", path: "qa/integration5.0snapshot.sh"

  config.vm.provider :virtualbox do |vb|
    vb.memory = 6144
    vb.cpus = 4
    #vb.gui = true
    #vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate//vagrant","1"]
  end
  
#  config.vm.synced_folder "..\\test\\", "/test", create: true
#  config.vm.synced_folder "./", "/vagrant", create: true
  
#  config.vm.provision :shell do |sh|
#    sh.path = config.bootstrap.privileged
#    sh.privileged = true
#  end

#  config.vm.provision :shell do |sh|
#    sh.path = config.bootstrap.non_privileged
#    sh.privileged = false
#  end
  
end

