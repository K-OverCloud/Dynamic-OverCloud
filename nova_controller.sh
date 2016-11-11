#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


M_IP=10.10.10.51
C_IP=192.168.88.51
D_IP=10.10.20.51
#RABBIT_PASS=secrete
PASSWORD=PASS
#ADMIN_TOKEN=ADMIN
#MAIL=jshan@nm.gist.ac.kr


# Install and Configure Nova Controller Node

#Prerequisites

#1.To create the database, complete these steps:
cat << EOF | mysql -uroot -p$PASSWORD
CREATE DATABASE nova_api;
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$PASSWORD';
quit
EOF



#2.Source the admin credentials to gain access to admin-only CLI commands:
source admin-openrc.sh

#3.To create the service credentials, complete these steps:
#◦Create the nova user:
openstack user create --domain default \
  --password $PASSWORD nova

#◦Add the admin role to the nova user:
openstack role add --project service --user nova admin

#◦Create the nova service entity:
openstack service create --name nova \
  --description "OpenStack Compute" compute


#4.Create the Compute service API endpoints:
openstack endpoint create --region RegionOne \
  compute public http://$C_IP:8774/v2.1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  compute internal http://$C_IP:8774/v2.1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  compute admin http://$C_IP:8774/v2.1/%\(tenant_id\)s


#Install and configure components

#1.Install the packages:
sudo apt-get install -y nova-api nova-conductor nova-consoleauth \
  nova-novncproxy nova-scheduler

#2.Edit the /etc/nova/nova.conf file and complete the following actions:
sed -i "s/enabled_apis=osapi_compute,metadata/enabled_apis=osapi_compute,metadata\n\
my_ip = $C_IP\n\
use_neutron = True \n\
firewall_driver = nova.virt.firewall.NoopFirewallDriver\n\
rpc_backend = rabbit\n\
auth_strategy = keystone/g" /etc/nova/nova.conf



sed -i "s/connection=sqlite:\/\/\/\/var\/lib\/nova\/nova.sqlite//g" /etc/nova/nova.conf

sed -i "s/\[database\]/\[database\]\n\
connection = mysql+pymysql:\/\/nova:$PASSWORD@$C_IP\/nova/g" /etc/nova/nova.conf

sed -i "s/\[api_database\]/\[api_database\]\n\
connection = mysql+pymysql:\/\/nova:$PASSWORD@$C_IP\/nova_api\n\
\n\
[oslo_messaging_rabbit]\n\
rabbit_host = $C_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $PASSWORD\n\
\n\
[keystone_authtoken]\n\
auth_uri = http:\/\/$C_IP:5000\n\
auth_url = http:\/\/$C_IP:35357\n\
memcached_servers = $C_IP:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = nova\n\
password = $PASSWORD\n\
\n\
[vnc]\n\
vncserver_listen = $C_IP\n\
vncserver_proxyclient_address = $C_IP\n\
novncproxy_base_url = http:\/\/$M_IP:6080\/vnc_auto.html\n\
\n\
[glance]\n\
api_servers = http:\/\/$C_IP:9292/g" /etc/nova/nova.conf

sed -i "s/lock_path=\/var\/lock\/nova/lock_path = \/var\/lib\/nova\/tmp/g" /etc/nova/nova.conf


#3.Populate the Compute databases:
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova


#•Restart the Compute services:
service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart




