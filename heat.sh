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


#Prerequisites

#1.To create the database, complete these steps:
cat << EOF | mysql -uroot -p$PASSWORD
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$PASSWORD';
quit
EOF

#2.Source the admin credentials to gain access to admin-only CLI commands:
source admin-openrc.sh

#3.To create the service credentials, complete these steps:

#◦Create the heat user:
openstack user create --domain default --password $PASSWORD heat

#◦Add the admin role to the heat user:
openstack role add --project service --user heat admin

#◦Create the heat and heat-cfn service entities:
openstack service create --name heat \
  --description "Orchestration" orchestration

openstack service create --name heat-cfn \
  --description "Orchestration"  cloudformation

#4.Create the Orchestration service API endpoints:
openstack endpoint create --region RegionOne \
  orchestration public http://$C_IP:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  orchestration internal http://$C_IP:8004/v1/%\(tenant_id\)s

 openstack endpoint create --region RegionOne \
  orchestration admin http://$C_IP:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  cloudformation public http://$C_IP:8000/v1

openstack endpoint create --region RegionOne \
  cloudformation internal http://$C_IP:8000/v1

openstack endpoint create --region RegionOne \
  cloudformation admin http://$C_IP:8000/v1

#5.Orchestration requires additional information in the Identity service to manage stacks. To add this information, complete these steps:

#◦Create the heat domain that contains projects and users for stacks:
openstack domain create --description "Stack projects and users" heat

#◦Create the heat_domain_admin user to manage projects and users in the heat domain:
openstack user create --domain heat --password $PASSWORD heat_domain_admin

#◦Add the admin role to the heat_domain_admin user in the heat domain to enable administrative stack management privileges by the heat_domain_admin user:
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

#◦Create the heat_stack_owner role:
openstack role create heat_stack_owner

#◦Add the heat_stack_owner role to the demo project and user to enable stack management by the demo user:
openstack role add --project demo --user demo heat_stack_owner

#◦Create the heat_stack_user role:
openstack role create heat_stack_user


#Install and configure components

#1.Install the packages:
sudo apt-get install -y heat-api heat-api-cfn heat-engine

#2.Edit the /etc/heat/heat.conf file and complete the following actions:
sed -i "s/#connection = <None>/connection = mysql+pymysql:\/\/heat:$PASSWORD@$C_IP\/heat/g" /etc/heat/heat.conf

sed -i "s/#rpc_backend = rabbit/rpc_backend = rabbit/g" /etc/heat/heat.conf

sed -i "s/#rabbit_host = localhost/rabbit_host = $C_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $PASSWORD/g" /etc/heat/heat.conf

sed -i "s/# From keystonemiddleware.auth_token/auth_uri = http:\/\/$C_IP:5000\n\
auth_url = http:\/\/$C_IP:35357\n\
memcached_servers = $C_IP:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = heat\n\
password = $PASSWORD/g" /etc/heat/heat.conf


sed -i "s/# Deprecated group\/name - \[trustee\]\/auth_plugin/auth_type = password\n\
auth_url = http:\/\/$C_IP:35357\n\
username = heat\n\
password = $PASSWORD\n\
user_domain_name = default/g" /etc/heat/heat.conf

sed -i "s/\[clients_keystone\]/\[clients_keystone\]\n\
auth_uri = http:\/\/$C_IP:35357/g" /etc/heat/heat.conf

sed -i "s/\[ec2authtoken\]/\[ec2authtoken\]\n\
auth_uri = http:\/\/$C_IP:5000/g" /etc/heat/heat.conf

sed -i "s/#debug = false/heat_metadata_server_url = http:\/\/$C_IP:8000\n\
heat_waitcondition_server_url = http:\/\/$C_IP:8000\/v1\/waitcondition\n\
stack_domain_admin = heat_domain_admin\n\
stack_domain_admin_password = $PASSWORD\n\
stack_user_domain_name = heat/g" /etc/heat/heat.conf

#3.Populate the Orchestration database:
su -s /bin/sh -c "heat-manage db_sync" heat

#restart the Orchestration services:
service heat-api restart
service heat-api-cfn restart
service heat-engine restart










