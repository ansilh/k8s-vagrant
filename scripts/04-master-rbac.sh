#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Create RBAC rule for API server to kubelet access
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------

source libs.sh

echo "[SCRIPT][RBAC] Creating RBAC for kube-apiserver-to-kubelet"
cat <<EOF >kube-apiserver-to-kubelet-cr.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
adjust_spec_version kube-apiserver-to-kubelet-cr.yaml
kubectl apply --kubeconfig admin.kubeconfig -f kube-apiserver-to-kubelet-cr.yaml

cat <<EOF >kube-apiserver-to-kubelet-crb.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
adjust_spec_version kube-apiserver-to-kubelet-crb.yaml
kubectl apply --kubeconfig admin.kubeconfig -f kube-apiserver-to-kubelet-crb.yaml