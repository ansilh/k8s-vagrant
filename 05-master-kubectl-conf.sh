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
  KUBERNETES_ADDRESS=$(grep $(hostname) /etc/hosts |awk '{print $1}')

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
  sudo bash -c "kubectl completion bash >.bash_profile;chown ${USER}:${USER} .bash_profile"
  sudo cp .bash_profile /home/ubuntu/
  sudo cp .kube/config /home/ubuntu/.kube/
  sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
  sudo chown ubuntu:ubuntu /home/ubuntu/.bash_profile
}
