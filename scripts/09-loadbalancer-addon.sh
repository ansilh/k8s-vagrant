#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Install and configure MetalLB loadbalancer
# - Assuming that user reserved last 50 IPs in subnet
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   12/04/2018
#----------------------------------------------------

LB_IP_RANGE=$(awk '/ip: /{print $2}' ~/.k8sconfig |head -1|awk -F "." '{print $1"."$2"."$3".200-"$1"."$2"."$3".250"}')

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

cat <<EOF |kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${LB_IP_RANGE}
EOF
