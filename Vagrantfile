#----------------------------------------------------
# Vagrantfile does below
# - Reads config.yaml and deploy master and worker nodes
# - A set of provisioning scripts will be called duing deployment which configures k8s cluster
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------
require 'yaml'
require 'net/ssh'

# Exit if config.yaml doesn't exist

if File.file?('config.yaml')
  conf = YAML.load_file('config.yaml')
else
  raise "Configuration file 'config.yaml' does not exist."
end

# Generate SSH key files to bootstrap kubernetes workers

if(File.file?('id_rsa'))
  puts 'Key file exists'
else
  key = OpenSSL::PKey::RSA.new 2048

  private_key = key.to_pem()
  type = key.ssh_type
  data = [ key.public_key.to_blob ].pack('m0')
  public_key = "#{type} #{data}"

  rsaFile = File.new('id_rsa', 'wb')
  rsaFile.write("#{private_key}")
  rsaFile.close

  rsaPubFile = File.new('id_rsa.pub', 'wb')
  rsaPubFile.write(public_key)
  rsaPubFile.close
end

# Script for both compute and control plane

$script = <<-SCRIPT
echo "Dummy scriipt hook for future use"
SCRIPT

# Download all scripts from Github repo
# TODO : Move scripts to a different derectory
GIT_BASE_URL = 'https://raw.githubusercontent.com/ansilh/k8s-vagrant/master/'

$keygen = <<-KEYGEN
echo "[SCRIPT][INFO] Changing password of user 'ubuntu'"
echo ubuntu:nutanix |  chpasswd
echo "[SCRIPT][INFO] Creating SSH Key for vagrant user"
su - vagrant -c "ssh-keygen -b 2048 -t rsa -f /home/vagrant/.ssh/id_rsa -q -N ''"
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart ssh
echo "[SCRIPT][INFO] Enabling packet forwarding"
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
echo "[SCRIPT][INFO] Enabling resolved"
systemctl enable systemd-resolved.service
systemctl start  systemd-resolved.service
KEYGEN


Vagrant.configure("2") do |config|
		conf.each do |host|
		config.vm.define host['name'] do |node|
			node.vm.box = host['box']
			node.vm.box_version = host['boxVersion']
			node.vm.hostname = host['name']
			node.vm.network :private_network, ip: host['ip']
			node.vm.provision "file", source: "config.yaml", destination: "~/.k8sconfig.win"
			node.vm.provision "shell", inline: "tr -d '\015' </home/vagrant/.k8sconfig.win >/home/vagrant/.k8sconfig"
			node.vm.provision "shell", inline: $keygen
			ssh_pub_key = File.readlines("id_rsa.pub").first.strip
			node.vm.provision 'shell', inline: $script, args: [host['type'], "test"]
			node.vm.provider :virtualbox do |vb|
				vb.name = host['name']
				vb.memory = 2048
			end
			node.vm.provision "file", source: "id_rsa", destination: "~/.ssh/id_rsa"
			node.vm.provision "file", source: "id_rsa.pub", destination: "~/.ssh/id_rsa.pub"
			node.vm.provision 'shell', inline: "chmod 600 /home/vagrant/.ssh/id_rsa"
			node.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys", privileged: false
			node.vm.provision 'shell', path: GIT_BASE_URL + "downloader.sh", args:[host['type']], privileged: false
			if host['type'] == 'Master'
				node.vm.provision 'shell', path: GIT_BASE_URL + "01-master-pki.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "02-master-etcd.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "03-master-controller.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "04-master-rbac.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "05-master-kubectl-conf.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "06-worker.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "07-master-calico.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "08-coredns-addon.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "09-loadbalancer-addon.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "10-metric-server-addon.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "11-dash-board-addon.sh", privileged: false
				node.vm.provision 'shell', path: GIT_BASE_URL + "12-ingress-controller.sh", privileged: false
			else
				node.vm.provision 'shell', path: GIT_BASE_URL + "06-worker.sh", privileged: false
			end

		end
	end
end
