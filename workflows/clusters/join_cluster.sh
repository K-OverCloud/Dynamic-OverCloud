#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

Join_Data="kubeadm join 210.125.84.200:6443 --token jy04wy.75vdsuen2eym1mza --discovery-token-ca-cert-hash sha256:3bf4fae189003763be2ba49383d52596c55210b8033051f88904ae24f78e6977"

Public_IP=" "

# Kubeadm Join
$Join_Data

# editing kubelet configuration
echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$Public_IP\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl restart kubelet
