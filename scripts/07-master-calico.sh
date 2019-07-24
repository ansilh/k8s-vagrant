#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Download and configures calico CNI
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------

# Service IP for Etcd
sed -i 's/10.96.232.136/172.168.0.10/g' etcd.yaml
kubectl apply -f etcd.yaml
kubectl apply -f rbac.yaml

# IP range for pods
sed -i 's/192.168.0.0/10.10.0.0/g' calico.yaml

# Replace the default etcd endpoint with ours 
sed -i 's/10.96.232.136/172.168.0.10/g' calico.yaml
kubectl apply -f calico.yaml
