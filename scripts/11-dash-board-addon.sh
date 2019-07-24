#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Downloads all yamls files for DashBoard
# - Modifies heapster to use proper source
# - Modifies the role to access node/stat for heapster
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   12/21/2018
#----------------------------------------------------

X="- apiGroups:
  - \"\"
  resources:
  - nodes/stats
  verbs:
  - get"

kubectl get clusterroles system:heapster -o yaml >heapster_role.yaml
echo "${X}" >>heapster_role.yaml
kubectl apply -f heapster_role.yaml

mkdir dash-board
cd dash-board

YAML_FILES="grafana.yaml
heapster.yaml
influxdb.yaml"

for FILE in ${YAML_FILES}
do
 wget -q https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/${FILE}
done
cd ..
wget -q https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

sed -i 's@--source=kubernetes:https://kubernetes\.default@--source=kubernetes.summary_api:https://kubernetes.default?kubeletHttps=true\&kubeletPort=10250\&insecure=true@' dash-board/heapster.yaml

kubectl create -f dash-board
kubectl create -f heapster-rbac.yaml
sleep 10
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl create serviceaccount cluster-admin-dashboard-sa
kubectl create clusterrolebinding cluster-admin-dashboard-sa \
  --clusterrole=cluster-admin \
  --serviceaccount=default:cluster-admin-dashboard-sa

kubectl describe secret $(kubectl get secret | grep cluster-admin-dashboard-sa|awk '{print $1}') |awk '/token/{print $2}' >~/.dash_token
