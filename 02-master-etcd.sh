#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Download etcd v3.3.9-linux-amd64
# - Configure systemd service file and starts
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------

{
  tar -xvf etcd-v3.3.9-linux-amd64.tar.gz >/dev/null
  sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
}
{
  MASTER=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /name/{print $2}'|head -1)
  echo "[SCRIPT][ETCD][INFO] Downloading Certs from Master ${MASTER}"
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kubernetes-key.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kubernetes.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/ca.pem .
}
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
}
INTERNAL_IP=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)
ETCD_NAME=$(hostname -s)
echo "[SCRIPT][ETCD][INFO] Setting up etcd.."
echo "[SCRIPT][ETCD][INFO] Etcd IP and name - ${INTERNAL_IP}, ${ETCD_NAME}"
cat <<EOF | sudo tee /etc/systemd/system/etcd.service >/dev/null
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${ETCD_NAME}=https://${INTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
sleep 10
echo "[SCRIPT][ETCD][INFO] etcd health status "
echo "########################################"
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
echo "########################################"
