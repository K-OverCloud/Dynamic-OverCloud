#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

IP="210.125.84.200"


kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address $IP >> data

mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config



cat data | grep kubeadm | grep join >> join_data
rm data

