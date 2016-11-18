#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


M_IP=10.10.10.10
C_IP=10.10.10.10
D_IP=10.10.10.10
CTR_M_IP=10.10.10.10
CTR_C_IP=10.10.10.10
#RABBIT_PASS=secrete
PASSWORD=PASS
#ADMIN_TOKEN=ADMIN
#MAIL=jshan@nm.gist.ac.kr


# Install and Configure Nova Controller Node

#Install and configure components

#1.Install the packages:
sudo apt-get install -y nova-compute

#2.Edit the /etc/nova/nova.conf file and complete the following actions:
sed -i "s/enabled_apis=ec2,osapi_compute,metadata/enabled_apis=ec2,osapi_compute,metadata\n\
rpc_backend = rabbit\n\
auth_strategy = keystone\n\
my_ip = $C_IP\n\
use_neutron = True\n\
firewall_driver = nova.virt.firewall.NoopFirewallDriver\n\
\n\
[oslo_messaging_rabbit]\n\
rabbit_host = $CTR_C_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $PASSWORD\n\
\n\
[keystone_authtoken]\n\
auth_uri = http:\/\/$CTR_C_IP:5000\n\
auth_url = http:\/\/$CTR_C_IP:35357\n\
memcached_servers = $CTR_C_IP:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = nova\n\
password = $PASSWORD\n\
\n\
[vnc]\n\
enabled = True\n\
vncserver_listen = 0.0.0.0\n\
vncserver_proxyclient_address = $C_IP\n\
novncproxy_base_url = http:\/\/$CTR_M_IP:6080\/vnc_auto.html\n\
\n\
[glance]\n\
api_servers = http:\/\/$CTR_C_IP:9292\n\
\n\
[oslo_concurrency]\n\
lock_path = \/var\/lib\/nova\/tmp/g" /etc/nova/nova.conf

#Finalize installation

#1.Determine whether your compute node supports hardware acceleration for virtual machines:
NUM=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $NUM = 0 ]
then
 echo "here"
 sed -i "s/virt_type=kvm/virt_type=qemu/g" /etc/nova/nova-compute.conf
fi

#2.Restart the Compute service:
service nova-compute restart

#Permission 
chown -R nova:nova /var/lib/nova

