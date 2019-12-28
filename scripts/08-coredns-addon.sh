#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - CoreDNS AddOn configuration
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
#----------------------------------------------------

kubectl apply -f coredns.yaml
# TODO: Write function to check calico readiness
