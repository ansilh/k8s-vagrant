#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - Configures Ingress using Traefik
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   12/28/2018
#----------------------------------------------------

# Apply RBAC rules for traefik
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-rbac.yaml

# Download deployment yaml and change service IP type to LoadBalancer
wget -q https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-deployment.yaml
sed -i 's/type: NodePort/type: LoadBalancer/' traefik-deployment.yaml
kubectl apply -f traefik-deployment.yaml

# Download Traefik UI yaml and change the virtual hostname from default to traefik-ui.linxlabs.local 
wget -q https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/ui.yaml
sed -i 's/traefik-ui.minikube/traefik-ui.linxlabs.local/' ui.yaml
kubectl apply -f ui.yaml
