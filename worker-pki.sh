#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Generate PKI Infrastructure and Kubeconfig files
# - Copy files to all master and worker nodes
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/30/2018
#----------------------------------------------------

# Generate certificates

instance=${1}
IP=${2}
KUBERNETES_ADDRESS=$(grep -w $(grep -w Master -B 2  ~/.k8sconfig |grep name: |awk '{print $3}') /etc/hosts |awk '{print $1}')
echo "[SCRIPT][KUBECONFIG][INFO] Creating kubeconfigs for worker node ${instance} - ${IP}"
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "IN",
      "L": "Bangalore",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way with vBox",
      "ST": "Karnataka"
    }
  ]
}
EOF

# Generate kubelet file

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${IP} \
  -profile=kubernetes \
  ${instance}-csr.json 2>/dev/null| cfssljson -bare ${instance}

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig >/dev/null

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig >/dev/null

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig >/dev/null

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig >/dev/null
