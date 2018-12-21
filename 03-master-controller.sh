#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Download Control Plane Binaries
# - Configure systemd service files and starts
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------
echo "[SCRIPT][CONTROLLER][INFO] Installing 'jq'..."
{
  #export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update >/dev/null
  sudo apt-get -y install jq >/dev/null
}

# This function serves two purpose
# 1. Checks API is up or not
# 2. Checks whether ClusterRole object is up or not

api_status(){
echo "[SCRIPT][CONTROLLER][INFO] Waiting for API to initialize.."
MASTER=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)
while true
do
  API_STATUS=$(curl -s -w '%{http_code}' --connect-timeout 1 --max-time 1 \
  --cacert /var/lib/kubernetes/ca.pem \
  --key /var/lib/kubernetes/kubernetes-key.pem \
  --cert /var/lib/kubernetes/kubernetes.pem \
  https://${MASTER}:6443/healthz)

  if [ ! -z "${API_STATUS}" ] && [ "${API_STATUS}" == "ok200"  ]
  then
    echo "[SCRIPT][CONTROLLER][INFO] API is up"
    break
  fi
done
}

sudo mkdir -p /etc/kubernetes/config
{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler
  sudo mv kube-apiserver kube-controller-manager kube-scheduler /usr/local/bin/
}
{
  MASTER=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)
  echo "[SCRIPT][CONTROLLER][INFO] Downloading Certs from ${MASTER}"
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/ca.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/ca-key.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kubernetes-key.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kubernetes.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/service-account-key.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/service-account.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/encryption-config.yaml .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/front-proxy/front-proxy-ca.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/front-proxy/front-proxy.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/front-proxy/front-proxy-key.pem .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kube-controller-manager.kubeconfig .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kube-scheduler.kubeconfig .
  scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/admin.kubeconfig .
}

{
  sudo mkdir -p /var/lib/kubernetes/
  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml front-proxy-ca.pem front-proxy.pem front-proxy-key.pem /var/lib/kubernetes/
}
INTERNAL_IP=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service >/dev/null
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://${INTERNAL_IP}:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=172.168.0.0/16 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --requestheader-client-ca-file=/var/lib/kubernetes/ca.pem \\
  --requestheader-client-ca-file=/var/lib/kubernetes/front-proxy-ca.pem \\
  --enable-aggregator-routing=true \\
  --requestheader-allowed-names=front-proxy-ca \\
  --requestheader-extra-headers-prefix=X-Remote-Extra- \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --proxy-client-cert-file=/var/lib/kubernetes/front-proxy.pem \\
  --proxy-client-key-file=/var/lib/kubernetes/front-proxy-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service >/dev/null
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.10.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=172.168.0.0/16 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml >/dev/null
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service >/dev/null
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}

# Wait for API server to initialize before moving to next step
api_status
