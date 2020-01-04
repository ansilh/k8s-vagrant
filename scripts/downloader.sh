#!/usr/bin/env bash

#---------------------------------------------------------------------------------------------------
# Scripts does below
# - Download all bins using wget wrapper to minimise vagrant output
#---------------------------------------------------------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
# Change Log: 
#  04/13/2019 : Flexible & de-duped download URLs
#  12/29/2019 : Removed calico rbac yaml as its bundled in main yaml in v3.8
#---------------------------------------------------------------------------------------------------

# To control git url path based on branch
GIT_BASE_URL=${2}

# To store remote file size
CONTENT_LEN=0

# Get the size of the file by reading header
get_file_size(){
  URL=${1}
  echo -e "Trying to download \n ${1} \n"
  CONTENT_LEN=$(curl -sLIXGET $URL | awk '/^Content-Length:/{print $2}'| tr -d '\r')
}

# Intiate download and send the download job to background
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

# Ongoing download tracker with progress indicator
# We need only four download status update on screen
#   1.Devide total size of file with 4 (for 25% progress)
#   2.Sent the download job to background
#   3.Track download size and update status on screen
#   TODO : Add timeout for download
track_file(){  
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

# Download function
get_bins(){
  get_file_size ${1}
  download_file ${1}
  track_file $(basename ${1})
}

# Download version file 
echo "Downloading ${GIT_BASE_URL}/VERSIONS"
get_bins ${GIT_BASE_URL}/VERSIONS
source VERSIONS

# Display downloaded version file on screen - debugging purpose
echo 
echo "**** Component Versions ****"
echo 
cat VERSIONS
echo 
echo "**** ------------------ ****"
echo 

# CFSSL URLs 
CFSSL_BIN_BASE="https://pkg.cfssl.org"
CFSSL_LINUX_URL=${CFSSL_BIN_BASE}"/R1.2/cfssl_linux-${BIN_TYPE}"
CFSSL_LINUX_JSON_URL=${CFSSL_BIN_BASE}"/R1.2/cfssljson_linux-${BIN_TYPE}"
YQ_URL="https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_${BIN_TYPE}"
# Kubernetes binary URLs 
K8S_BIN_BASE="https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}"
K8S_API_URL="${K8S_BIN_BASE}/bin/linux/${BIN_TYPE}/kube-apiserver"
K8S_CTR_URL="${K8S_BIN_BASE}/bin/linux/${BIN_TYPE}/kube-controller-manager"
K8S_SCHED_URL="${K8S_BIN_BASE}/bin/linux/${BIN_TYPE}/kube-scheduler"
K8S_CTL_URL="${K8S_BIN_BASE}/bin/linux/${BIN_TYPE}/kubectl"
K8S_PROXY_URL="${K8S_BIN_BASE}/bin/linux/${BIN_TYPE}/kube-proxy"
K8S_KUBELET_URL="${K8S_BIN_BASE}/bin/linux/${BIN_TYPE}/kubelet"

# Misc URLs 
COREDNS_YAML="https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed"
ETCD_URL="https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${BIN_TYPE}.tar.gz"
CRI_URL="https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRI_TOOLS_VERSION}/crictl-${CRI_TOOLS_VERSION}-linux-${BIN_TYPE}.tar.gz"
RUNSC_URL="https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17"
RUNC_URL="https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${BIN_TYPE}"
CONTAINERD_URL="https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}.linux-${BIN_TYPE}.tar.gz"
CALICO_BASE="https://docs.projectcalico.org/${CALICO_VERSION}/getting-started/kubernetes/installation"
WORKER_PKI_URL="${GIT_BASE_URL}/worker-pki.sh"
WORKFLOW_LIB="${GIT_BASE_URL}/libs.sh"
METALLB="https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml"
# Download binaries based on the node role
# Master node will also act as worker node , thus more bins for master node
if [ ${1} == "Master" ]
then
	for BIN_URL in  \
"${CFSSL_LINUX_URL}" \
"${CFSSL_LINUX_JSON_URL}" \
"${YQ_URL}" \
"${K8S_API_URL}" \
"${K8S_CTR_URL}" \
"${K8S_SCHED_URL}" \
"${K8S_CTL_URL}" \
"${ETCD_URL}" \
"${CRI_URL}" \
"${RUNSC_URL}" \
"${RUNC_URL}" \
"${CONTAINERD_URL}" \
"${K8S_PROXY_URL}" \
"${K8S_KUBELET_URL}" \
"${CALICO_BASE}/hosted/etcd.yaml" \
"${CALICO_BASE}/hosted/calico.yaml" \
"${COREDNS_YAML}" \
"${WORKER_PKI_URL}" \
"${WORKFLOW_LIB}" \
"${METALLB}"
  do
		get_bins "${BIN_URL}"
	done
else
	for BIN_URL in  \
	"${CRI_URL}" \
	"${RUNSC_URL}" \
	"${RUNC_URL}" \
	"${CONTAINERD_URL}" \
	"${K8S_CTL_URL}" \
	"${K8S_PROXY_URL}" \
	"${K8S_KUBELET_URL}"
	do
		get_bins "${BIN_URL}"
	done
fi
