#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Downloads all yamls files
# - Modifies deployment to mount local hosts file
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   12/04/2018
#----------------------------------------------------

source libs.sh

YAMLS="aggregated-metrics-reader.yaml
auth-delegator.yaml
auth-reader.yaml
metrics-apiservice.yaml
metrics-server-deployment.yaml
metrics-server-service.yaml
resource-reader.yaml"

mkdir metric-server
cd metric-server

for FILE in ${YAMLS}
do
#  wget -q https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/${FILE}
  wget -q raw.githubusercontent.com/kubernetes-sigs/metrics-server/master/deploy/kubernetes/${FILE}
  adjust_spec_version ${FILE}
done

VOLUME="\      - name: hosts\n\        hostPath:\n\         path: /etc/hosts"
VOLUME_MOUNTS="\        - name: hosts\n\          mountPath: /etc/hosts"
sed -i "/volumes:/a ${VOLUME}" metrics-server-deployment.yaml
sed -i "/volumeMounts:/a ${VOLUME_MOUNTS}" metrics-server-deployment.yaml
sed -i '/cert-dir/i\        - --kubelet-insecure-tls \
        - --kubelet-preferred-address-types=InternalIP' metrics-server-deployment.yaml
cd ..
kubectl create -f metric-server/

# kubectl describe apiservices v1beta1.metrics.k8s.io
