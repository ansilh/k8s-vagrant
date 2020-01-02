#!/usr/bin/env bash

#----------------------------------------------------
# Scripts does below
# - CoreDNS AddOn configuration
#----------------------------------------------------
# Author: Ansil H (ansilh@gmail.com)
# Date:   11/25/2018
# Log:
# 01/01/2020: Modified to adapt proper API versions
#----------------------------------------------------
source libs.sh
mv coredns.yaml.sed coredns.yaml

# for i in $(egrep --no-group-separator "apiVersion" -A 1 coredns.yaml.sed  |sed -e 'N;s/\n/|/g' -e 's/ //g')
# do
#         API_VERSION=$(echo $i|awk -F "|" '{print $1}'|awk -F ":" '{print $2}')
#         KIND=$(echo $i|awk -F "|" '{print $2}'|awk -F ":" '{print $2}')
#         NEW_API_VERSION=$(kubectl explain ${KIND} |grep VERSION |awk '{print $2}')
#         sed -i "s@apiVersion: ${API_VERSION}@apiVersion: ${NEW_API_VERSION}@" coredns.yaml
# done

NAMESERVER=$(grep nameserver /etc/resolv.conf |head -1|awk '{print $2}')
CLUSTER_DOMAIN="cluster.local"
REVERSE_CIDRS="in-addr.arpa ip6.arpa"
CLUSTER_DNS_IP="172.168.0.2"
sed -i "s@UPSTREAMNAMESERVER@${NAMESERVER}@" coredns.yaml
sed -i "s@CLUSTER_DOMAIN@${CLUSTER_DOMAIN}@" coredns.yaml
sed -i "s@REVERSE_CIDRS@${REVERSE_CIDRS}@" coredns.yaml
sed -i "s@FEDERATIONS@@" coredns.yaml
sed -i "s@STUBDOMAINS@@" coredns.yaml
sed -i "s@CLUSTER_DNS_IP@${CLUSTER_DNS_IP}@" coredns.yaml
adjust_spec_version coredns.yaml
kubectl apply -f coredns.yaml
# TODO: Write function to check calico readiness
