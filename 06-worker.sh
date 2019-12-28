#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Creates service files for each worker plane components
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------
add_label_taint(){
  LABEL_START="{\"metadata\":{\"labels\":{\""
  LABEL_END="\":\"\"}}}"
  JQ_START=".metadata .labels|has("
  JQ_END=")"

  # Extract certificates from kubeconfig
  #cat /var/lib/kubelet/kubeconfig|awk '/certificate-authority-data:/{print $2}' |base64 -d >ca-curl.pem
  #cat /var/lib/kubelet/kubeconfig|awk '/client-certificate-data:/{print $2}' |base64 -d >cert-curl.pem
  #cat /var/lib/kubelet/kubeconfig|awk '/client-key-data:/{print $2}' |base64 -d >key-curl.pem
  


  MASTER_NODE=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)
  NODE_NAME=$(hostname)
  scp -oStrictHostKeyChecking=no ${MASTER_NODE}:~/PKI/ca.pem ca-curl.pem
  scp -oStrictHostKeyChecking=no ${MASTER_NODE}:~/PKI/kubernetes-key.pem key-curl.pem
  scp -oStrictHostKeyChecking=no ${MASTER_NODE}:~/PKI/kubernetes.pem cert-curl.pem
  
  am_i_master(){
    echo "[SCRIPT][LABEL][INFO] Checking if node - $(hostname) - is marked as master"
    MY_ROLE=$(grep $(hostname) -A 2 ~/.k8sconfig |tail -1 |awk '{print $2}')
    if [ ! -z "${MY_ROLE}" ] && [ "${MY_ROLE}" == "Master" ]
    then
      return 0
    else
      return 1
    fi
  }

  node_status(){
   echo "[SCRIPT][LABEL][INFO] Waiting for node - ${NODE_NAME} - to come up"
   while true
    do
    API_STATUS=$(curl -s --cacert ca-curl.pem \
      --key key-curl.pem \
      --cert cert-curl.pem \
      https://${MASTER_NODE}:6443/api/v1/nodes/${NODE_NAME} |jq '.status .conditions[] |select(.type=="Ready")| .status' 2>/dev/null |sed 's/"//g')
      if [ ! -z "${API_STATUS}" ] && [ "${API_STATUS}" == "False" -o "${API_STATUS}" == "True"  ]
      then
        break
      fi
   done
  }

  node_status

  if am_i_master
  then
    VAL="node-role.kubernetes.io/master"
    TAINT='{"spec":{"taints":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master"}]}}'
  else
    VAL="node-role.kubernetes.io/worker"
    TAINT=""
  fi

  # Add taint if node is master

  if [ ! -z "${TAINT}" ]
  then
    TAINT_STATUS=$(curl -s -XPATCH  -H "Accept: application/json" \
    -H "Content-Type: application/merge-patch+json" \
    --data ${TAINT} --cacert ca-curl.pem --key key-curl.pem  --cert cert-curl.pem \
    https://${MASTER_NODE}:6443/api/v1/nodes/$(hostname) |jq '.spec .taints[]| select(.key == "node-role.kubernetes.io/master")|.effect' 2>/dev/null |sed 's/"//g')
    if [ ! -z "${TAINT_STATUS}" ] && [ "${TAINT_STATUS}" == "NoSchedule" ]
    then
      echo "[SCRIPT][LABEL][INFO] Tainted $(hostname)"
    else
      echo "[SCRIPT][LABEL][INFO] Taint failed on $(hostname)"
    fi
  fi


  # Add label to node using curl

  LABEL_NODE=$(curl -s -XPATCH  \
  -H "Accept: application/json" \
  -H "Content-Type: application/merge-patch+json" \
  --data "${LABEL_START}${VAL}${LABEL_END}" \
  --cacert ca-curl.pem \
  --key key-curl.pem  \
  --cert cert-curl.pem \
  https://${MASTER_NODE}:6443/api/v1/nodes/$(hostname)| jq "${JQ_START}\"${VAL}\"${JQ_END}")

  # Confirm whether label added correcly to node

  if [ ! -z "${LABEL_NODE}" ] && [ "${LABEL_NODE}" == "true" ]
  then
          echo "[SCRIPT][LABEL][INFO] Added role label to $(hostname) "
  else
          echo "[SCRIPT][LABEL][ERR]  Adding role label to $(hostname) failed"
          exit 1
  fi
}

# Generate certificate
MASTER=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /ip/{print $2}'|head -1)
MY_IP=$(grep $(hostname) -A 1 ~/.k8sconfig |tail -1 |awk '{print $2}')
{
  ssh -oStrictHostKeyChecking=no ${MASTER} "cd /home/vagrant/PKI; ./worker-pki.sh $(hostname) ${MY_IP}"
}
{
  #export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update >/dev/null
  sudo apt-get -y install socat conntrack ipset jq >/dev/null
}

sudo mkdir -p \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

#TODO# Add logic to retrieve versions from common place #

wget -q https://raw.githubusercontent.com/ansilh/k8s-vagrant/v1.14.0/version.sh
source version.sh

{
  sudo mv runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 runsc
  sudo mv runc.amd64 runc
  chmod +x kube-proxy kubelet runc runsc
  sudo mv kube-proxy kubelet runc runsc /usr/local/bin/
  sudo tar -xvf crictl-${CRI_TOOLS_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ >/dev/null
  sudo tar -xvf containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz -C / >/dev/null
}

sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.toml >/dev/null
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
    [plugins.cri.containerd.gvisor]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
EOF
cat <<EOF | sudo tee /etc/systemd/system/containerd.service >/dev/null
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF


MASTER=$(grep -w Master -B 2  ~/.k8sconfig |sed 's/ //g'|awk -F ":" '$1 ~ /name/{print $2}'|head -1)

scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/${HOSTNAME}-key.pem .
scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/${HOSTNAME}.pem .
scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/${HOSTNAME}.kubeconfig .
scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/ca.pem .
scp -oStrictHostKeyChecking=no ${MASTER}:~/PKI/kube-proxy.kubeconfig .

{
  sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.pem /var/lib/kubernetes/
}
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml >/dev/null
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "172.168.0.2"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/resolvconf/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service >/dev/null
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml >/dev/null
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.10.0.0/16"
EOF
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service >/dev/null
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
add_label_taint
