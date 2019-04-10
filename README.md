:fire: Development branch :fire:

# Carry a kubernetes cluster in your laptop

This project started for fun while preparing my CKA certification and there is no intention to put this as a serious project. ;)

* Software Versions
  - Vagrant Box : ubuntu/xenial64 (20181217.0.0)
  - K8S Version: v1.14.0
  - etcd Version: v3.3.9
  - containerd Version: v1.2.4
  - CRI tool Version: v1.14.0
  - runc Version: 1.0.0-rc6
* AddOns included
  - MetalLB loadbalancer
  - DashBoard
  - Grafana
  - MetricServer
  - Traefik Ingress controller
* Future AddOns
  - Prometheus

* How to Setup
  - [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)
  - [Install Vagrant](https://www.vagrantup.com/)
  - Download Vagrant file
```
$ wget https://raw.githubusercontent.com/ansilh/k8s-vagrant/master/Vagrantfile
```
 * Download config.yaml file (Modify if needed)
```
$ wget https://raw.githubusercontent.com/ansilh/k8s-vagrant/master/config.yaml
```
 * Execute vagrant up
```
$ vagrant up
```
* Default username and password to logon to nodes
```
User :ubuntu
Password: nutanix
```
* Cluster deployment demo (~10mins)

 [![Cluster deployment demo](https://raw.githubusercontent.com/ansilh/k8s-vagrant/master/k8s-demo.png)](https://www.youtube.com/watch?v=5bSrwGvdWw0&hd=1 "Cluster deployment demo")

If you have input , feel free to reachout [me](https://www.linkedin.com/in/ansil-h-%E2%98%81-48b61415/)
