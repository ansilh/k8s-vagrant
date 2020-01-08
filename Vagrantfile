#----------------------------------------------------
# Vagrantfile does below
# - Reads config.yaml and deploy master and worker nodes
# - A set of provisioning scripts will be called duing deployment which configures k8s cluster
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
# Change Log:
# 	04/13/2019: Moved scripts to a common directory
#               Added logic to read software versions from one place
#   24/07/2019: Added git branching with BRANCH
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
echo "Dummy script hook for future use"
SCRIPT

# Download all scripts from Github repo

BRANCH='/v1.17.0'

GIT_BASE_URL = "https://raw.githubusercontent.com/ansilh/k8s-vagrant" + "#{BRANCH}" 
SCRIPTS_PATH = "#{GIT_BASE_URL}" + "/scripts"

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
			node.vm.provision 'shell', path: SCRIPTS_PATH + "/downloader.sh", args:[host['type'], SCRIPTS_PATH ], privileged: false
			if host['type'] == 'Master'
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/01-master-pki.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/02-master-etcd.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/03-master-controller.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/04-master-rbac.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/05-master-kubectl-conf.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/06-worker.sh",args:[SCRIPTS_PATH], privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/07-master-calico.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/08-coredns-addon.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/09-loadbalancer-addon.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/10-metric-server-addon.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/11-dash-board-addon.sh", privileged: false
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/12-ingress-controller.sh", privileged: false
			else
				node.vm.provision 'shell', path: SCRIPTS_PATH + "/06-worker.sh",args:[GIT_BASE_URL], privileged: false
			end

		end
	end
end
