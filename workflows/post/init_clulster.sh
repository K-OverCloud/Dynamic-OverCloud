#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

IP=$1


# editing kubelet configuration
#echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$IP\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo sed -i "s/ARGS=/ARGS=--node-ip=$IP/g" /etc/default/kubelet

#systemctl daemon-reload
#systemctl restart kubelet



kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address $IP --ignore-preflight-errors all >> data

mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# It cannot print more than two serialized ouputs
# For example
#cat data | grep kubeadm | grep join >> join_data

# kubeadm join $IP:6443 --token ibrsl1.9n9mvb964xpi3vne \



# This command prints 2 lines of kubeadm join
# For example
# kubeadm join $IP:6443 --token ibrsl1.9n9mvb964xpi3vne \
#    --discovery-token-ca-cert-hash sha256:862ea2e70a606290398106d87d36e6260f78d298323953d64e3dd99817f9cbf7
grep -A2 "kubeadm join" data >> join_data


#rm data

