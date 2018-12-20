#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Downloads all yamls files
# - Modifies deployment to mount local hosts file
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   12/04/2018
#----------------------------------------------------

YAMLS="auth-delegator.yaml
auth-reader.yaml
metrics-apiservice.yaml
metrics-server-deployment.yaml
metrics-server-service.yaml
resource-reader.yaml"

mkdir metric-server
cd metric-server

for FILE in ${YAMLS}
do
  wget https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/${FILE}
done

VOLUME="\      - name: hosts\n\        hostPath:\n\         path: /etc/hosts"
VOLUME_MOUNTS="\        - name: hosts\n\          mountPath: /etc/hosts"
sed -i "/volumes:/a ${VOLUME}" metrics-server-deployment.yaml
sed -i "/volumeMounts:/a ${VOLUME_MOUNTS}" metrics-server-deployment.yaml

cd ..
kubectl create -f metric-server/

kubectl describe apiservices v1beta1.metrics.k8s.io
