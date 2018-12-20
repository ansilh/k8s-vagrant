# Carry a kubernetes cluster in your laptop

This project started for fun while preparing my CKA certification and there is no intention to put this as a serious project. ;)

* Software Versions (updates will happen soon)
 * k8s Version: v12.0.1
 * etcd Version: v3.3.9
 * containerd Version: v1.2.0-rc.0
 * runc Version: v1.0.0-rc5

* Network plugin - Calico

* AddOns included
 * MetalLB loadbalancer
 * DashBoard
 * Grafana
 * MetricServer

* Future AddOns
 * Ingress controller - Traefik

* How to Setup
 * [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)
 * [Install Vagrant](https://www.vagrantup.com/)
 * Download Vagrant file
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

* Cluster deployment demo (~10mins)

 [![Cluster deployment demo](https://raw.githubusercontent.com/ansilh/k8s-vagrant/master/k8s-demo.png)](https://www.youtube.com/watch?v=5bSrwGvdWw0&hd=1 "Cluster deployment demo")

Feel free comment to shoot me an email at ansilh@gmail.com
