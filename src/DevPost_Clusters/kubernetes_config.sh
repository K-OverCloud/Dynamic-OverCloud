#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


#Turn off swap
swapoff -a


# iptables to receive bridged network traffic
echo "net/bridge/bridge-nf-call-ip6tables = 1" >> /etc/ufw/sysctl.conf
echo "net/bridge/bridge-nf-call-iptables = 1" >> /etc/ufw/sysctl.conf
echo "net/bridge/bridge-nf-call-arptables = 1" >> /etc/ufw/sysctl.conf

service ufw restart

# install ebtables and ethtool
apt-get install -y ebtables ethtool

# Docker
apt-get update
apt-get install -y docker.io
apt-get install -y apt-transport-https curl

# kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl


