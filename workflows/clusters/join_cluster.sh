#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

Public_IP=$1


# editing kubelet configuration
#echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$Public_IP\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo sed -i "s/ARGS=/ARGS=--node-ip=$Public_IP/g" /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet
