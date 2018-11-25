#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Generate PKI Infrastructure and Kubeconfig files
# - Copy files to all master and worker nodes
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------
echo "[SCRIPT][PKI][INFO] Bin setup."
{
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
  sudo  mv cfssl_linux-amd64 /usr/local/bin/cfssl
  sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
}
echo "[SCRIPT][PKI][INFO] Creating PKI Infrastructure"
mkdir PKI
cd PKI
echo "[SCRIPT][PKI][INFO] Creating CA"
cat <<EOF >ca-config.json
{
    "signing": {
        "default": {
            "expiry": "8760h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
cat <<EOF >ca-csr.json
{
    "CN": "Kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "IN",
            "L": "KL",
            "O": "Kubernetes",
            "OU": "CA",
            "ST": "Kerala"
        }
    ]
}
EOF
cfssl gencert -initca ca-csr.json 2>/dev/null|cfssljson -bare ca
echo "[SCRIPT][PKI][INFO] Created CA"
echo "[SCRIPT][PKI][INFO] Creating Admin Certs"

{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
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

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json 2>/dev/null| cfssljson -bare admin

}

WORKER_NODES=$(grep -w Worker -B 2  ~/.k8sconfig |grep name: |awk '{print $3}')
MASTERS=$(grep -w $(grep -w Master -B 2  ~/.k8sconfig |grep name: |awk '{print $3}') /etc/hosts |awk '{print $2}')

echo "[SCRIPT][PKI][INFO] Worker Certs for ${WORKER_NODES} ${MASTERS}"
for instance in ${WORKER_NODES} ${MASTERS}; do
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
IP=$(grep -w ${instance} /etc/hosts |awk '{print $1}')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${IP} \
  -profile=kubernetes \
  ${instance}-csr.json 2>/dev/null| cfssljson -bare ${instance}
done

{

echo "[SCRIPT][PKI][INFO] Worker Certs for kube-controller-manager"
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
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

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json 2>/dev/null| cfssljson -bare kube-controller-manager

}
{

echo "[SCRIPT][PKI][INFO] Worker Certs for kube-proxy"
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
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

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json 2>/dev/null| cfssljson -bare kube-proxy

}

echo "[SCRIPT][PKI][INFO] Worker Certs for kube-scheduler"
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
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

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json 2>/dev/null| cfssljson -bare kube-scheduler

}

{
KUBERNETES_ADDRESS=$(grep -w $(grep -w Master -B 2  ~/.k8sconfig |grep name: |awk '{print $3}') /etc/hosts |awk '{print $1}')
echo "[SCRIPT][PKI][INFO] Worker Certs for kube-apiserver ${KUBERNETES_ADDRESS}"

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
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

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${KUBERNETES_ADDRESS},172.168.0.1,127.0.0.1,cluster.local,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json 2>/dev/null| cfssljson -bare kubernetes

}

{
echo "[SCRIPT][PKI][INFO] Worker Certs for Service Account"

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
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

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json 2>/dev/null| cfssljson -bare service-account

}
#-----------------
echo "[SCRIPT][KUBECONFIG][INFO] Creating kubeconfigs for worker nodes ${WORKER_NODES} ${MASTERS}"
for instance in ${WORKER_NODES} ${MASTERS}; do
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
done
echo "[SCRIPT][KUBECONFIG][INFO] Creating kubeconfigs for  kube-proxy"

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig >/dev/null

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig >/dev/null

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig >/dev/null

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig >/dev/null
}
echo "[SCRIPT][KUBECONFIG][INFO] Creating kubeconfigs for kube-controller-manager"
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig >/dev/null

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig >/dev/null

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig >/dev/null

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig >/dev/null
}

echo "[SCRIPT][KUBECONFIG][INFO] Creating kubeconfigs for kube-scheduler"
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig >/dev/null

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig >/dev/null

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig >/dev/null

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig >/dev/null
}
echo "[SCRIPT][KUBECONFIG][INFO] Creating kubeconfigs for admin user"

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig >/dev/null

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig >/dev/null

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig >/dev/null

  kubectl config use-context default --kubeconfig=admin.kubeconfig >/dev/null
}
echo "[SCRIPT][ENCRYPTION][INFO] Creating encryption key "
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
echo "[SCRIPT][AGGREGATION][INFO] Generating certs for Aggregation"
mkdir front-proxy
cd front-proxy
cat >ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "8760h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat >ca-csr.json <<EOF
{
    "CN": "Kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "IN",
            "L": "KL",
            "O": "Kubernetes",
            "OU": "CA",
            "ST": "Kerala"
        }
    ]
}
EOF

cfssl gencert -initca ca-csr.json 2>/dev/null|cfssljson -bare front-proxy-ca

cat >front-proxy-csr.json <<EOF
{
    "CN": "front-proxy-ca",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "IN",
            "L": "KL",
            "O": "Kubernetes",
            "OU": "CA",
            "ST": "Kerala"
        }
    ]
}
EOF

cfssl gencert \
   -ca=front-proxy-ca.pem \
   -ca-key=front-proxy-ca-key.pem \
   -config=ca-config.json \
   -profile=kubernetes \
   front-proxy-csr.json 2>/dev/null| cfssljson -bare front-proxy
