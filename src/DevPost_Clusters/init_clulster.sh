#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

kubeadm init --pod-network-cidr=192.168.0.0/16 >> data
cat data | grep kubeadm | grep join >> join_data
rm data

