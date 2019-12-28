#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Download all bins using wget wrapper to minimise vagrant output
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------

CONTENT_LEN=0
wget -q https://raw.githubusercontent.com/ansilh/k8s-vagrant/v1.14.0/version.sh
source version.sh
get_file_size(){
  # Get the size of the file by reading header
  URL=${1}
  CONTENT_LEN=$(curl -sLIXGET $URL | awk '/^Content-Length:/{print $2}'| tr -d '\r')
}
download_file(){
  FILE=$(basename ${1})
  DOWN_P=$(stat ${FILE} 2>/dev/null|grep Size  |awk '{print $2}')
  if [ ! -z ${DOWN_P} ] && [ ${DOWN_P} -ne ${CONTENT_LEN} ]
  then
    rm -f ${FILE}
  elif [ ! -z ${DOWN_P} ] && [ ${DOWN_P} -eq ${CONTENT_LEN} ]
  then
    return
  fi
  (wget -q "${1}" &)
}
track_file(){
  # We need only four download status update on screen
  # Device total size of file with 4
  # Sent the download job to background
  # Track download size and update status on screen

  PER=$(( CONTENT_LEN / 4 ))
  FIXED_PER=${PER}
  PER_D=25
  PER_FIXED=25
  DOWN_P=""
  while true
  do
    while [ -z ${DOWN_P} ]
    do
      DOWN_P=$(stat ${1} 2>/dev/null|grep Size  |awk '{print $2}')
    done
    DOWN_P=$(stat ${1} |grep Size  |awk '{print $2}')
    if [ ${DOWN_P} -gt ${PER} ] && [ ${DOWN_P} -lt ${CONTENT_LEN} ]
    then
      echo "Downloading ${1} - ${DOWN_P} of ${CONTENT_LEN} - ${PER_D}%"
      PER=$(expr ${PER} + ${FIXED_PER} )
      PER_D=$(expr ${PER_D} + ${PER_FIXED} )
    elif [ ${DOWN_P} -ge ${CONTENT_LEN} ]
    then
      echo "Downloaded ${1} - ${DOWN_P} of ${CONTENT_LEN} - 100%"
      break
    fi
  done

}
get_bins(){
  get_file_size ${1}
  download_file ${1}
  track_file $(basename ${1})
}

# Master node will also act as worker node , thus more bins for master node
# TODO: Imrpove download list using inout YAML file

if [ ${1} == "Master" ]
then
	for BIN_URL in  \
"https://pkg.cfssl.org/R1.2/cfssl_linux-amd64" \
"https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64" \
"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-apiserver" \
"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-controller-manager" \
"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-scheduler" \
"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl" \
"https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz" \
"https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRI_TOOLS_VERSION}/crictl-${CRI_TOOLS_VERSION}-linux-amd64.tar.gz" \
"https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17" \
"https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.amd64" \
"https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz" \
"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-proxy" \
"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubelet" \
"https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/etcd.yaml" \
"https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/rbac.yaml" \
"https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/calico.yaml" \
"https://raw.githubusercontent.com/ansilh/kubernetes-the-hardway-virtualbox/master/config/coredns.yaml" \
"https://raw.githubusercontent.com/ansilh/k8s-vagrant/v1.14.0/worker-pki.sh"
  do
		get_bins "${BIN_URL}"
	done
else
	for BIN_URL in  \
	"https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRI_TOOLS_VERSION}/crictl-${CRI_TOOLS_VERSION}-linux-amd64.tar.gz" \
	"https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17" \
	"https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.amd64" \
	"https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz" \
	"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl" \
	"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-proxy" \
	"https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubelet"
	do
		get_bins "${BIN_URL}"
	done
fi
