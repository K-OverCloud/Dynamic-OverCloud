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


#1.Install the packages:
sudo apt-get install -y openstack-dashboard

#2.Edit the /etc/openstack-dashboard/local_settings.py file and complete the following actions:
sed -i 's/OPENSTACK_HOST = "127.0.0.1"/OPENSTACK_HOST = "'$C_IP'"/g' /etc/openstack-dashboard/local_settings.py
sed -i "s/ALLOWED_HOSTS = '\*'/ALLOWED_HOSTS = \['\*', \]/g" /etc/openstack-dashboard/local_settings.py
sed -i "s/# memcached set CACHES to something like/# memcached set CACHES to something like\n\
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'/g" /etc/openstack-dashboard/local_settings.py
sed -i "s/'LOCATION': '127.0.0.1:11211'/'LOCATION': '$C_IP:11211'/g" /etc/openstack-dashboard/local_settings.py
sed -i "s/http:\/\/%s:5000\/v2.0/http:\/\/%s:5000\/v3/g" /etc/openstack-dashboard/local_settings.py

sed -i 's/#OPENSTACK_API_VERSIONS = {/OPENSTACK_API_VERSIONS = {/g' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "data-processing": 1.1,/"identity": 3,/g' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "identity": 3,/"image": 2,/g' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "volume": 2,/"volume": 2,/g' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "compute": 2,/}/g' /etc/openstack-dashboard/local_settings.py

sed -i "s/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/g" /etc/openstack-dashboard/local_settings.py

sed -i 's/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"/g' /etc/openstack-dashboard/local_settings.py

sed -i "s/'enable_distributed_router': False,/'enable_distributed_router': True,/g" /etc/openstack-dashboard/local_settings.py

# multidomain support
sed -i "s/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g" /etc/openstack-dashboard/local_settings.py


#•Reload the web server configuration:
service apache2 reload

