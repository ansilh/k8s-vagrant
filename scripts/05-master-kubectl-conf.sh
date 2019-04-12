#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Configure kubectl
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------

cd PKI
{
  KUBERNETES_ADDRESS=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --embed-certs=true \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
cd
{
  sudo mkdir /home/ubuntu/.kube/
  sudo bash -c "echo 'source <(kubectl completion bash)' >>/home/ubuntu/.bashrc;chown ${USER}:${USER} .bashrc"
  sudo cp .kube/config /home/ubuntu/.kube/
  sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
  sudo chown ubuntu:ubuntu /home/ubuntu/.bashrc
}
