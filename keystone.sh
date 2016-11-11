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



# Install & Configure Keystone



# Configure Mysql DB

cat << EOF | mysql -uroot -p$PASSWORD
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$PASSWORD';
quit
EOF

TOKEN=`openssl rand -hex 10`

#2.Run the following command to install the packages
sudo apt-get -y install keystone

#3.Edit the /etc/keystone/keystone.conf file and complete the following actions


#◦In the [database] section, configure database access:
sed -i "s/connection = sqlite:\/\/\/\/var\/lib\/keystone\/keystone.db/connection = mysql+pymysql:\/\/keystone:$PASSWORD@$C_IP\/keystone/g" /etc/keystone/keystone.conf

#◦In the [token] section, configure the Fernet token provider:
sed -i "s/#provider = uuid/provider = fernet/g" /etc/keystone/keystone.conf

sed -i "s/#verbose = True/verbose = True/g" /etc/keystone/keystone.conf

#4.Populate the Identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone

#5.Initialize Fernet keys:

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

#5.Bootstrap the Identity service:
keystone-manage bootstrap --bootstrap-password $PASSWORD \
  --bootstrap-admin-url http://$C_IP:35357/v3/ \
  --bootstrap-internal-url http://$C_IP:35357/v3/ \
  --bootstrap-public-url http://$C_IP:5000/v3/ \
  --bootstrap-region-id RegionOne

#1.Restart the Apache service and remove the default SQLite database:
service apache2 restart
rm -f /var/lib/keystone/keystone.db



#2.Configure the administrative account
export OS_USERNAME=admin
export OS_PASSWORD=$PASSWORD
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$C_IP:35357/v3
export OS_IDENTITY_API_VERSION=3




#3.This guide uses a service project that contains a unique user for each service that you add to your environment. Create the service project:
openstack project create --domain default \
  --description "Service Project" service

#4.Regular (non-admin) tasks should use an unprivileged project and user. As an example, this guide creates the demo project and user.
#◦Create the demo project:
openstack project create --domain default \
  --description "Demo Project" demo

#◦Create the demo user:
openstack user create --domain default \
  --password $PASSWORD demo

#◦Create the user role:
openstack role create user

#◦Add the user role to the demo project and user:
openstack role add --project demo --user demo user


#Unset the temporary OS_TOKEN and OS_URL environment variables:
unset OS_URL

#1.Edit the admin-openrc file and add the following content:
touch admin-openrc.sh
echo "export OS_PROJECT_DOMAIN_NAME=default" >> admin-openrc.sh
echo "export OS_USER_DOMAIN_NAME=default" >> admin-openrc.sh
echo "export OS_PROJECT_NAME=admin" >> admin-openrc.sh
echo "export OS_USERNAME=admin" >> admin-openrc.sh
echo "export OS_PASSWORD=$PASSWORD" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://$C_IP:35357/v3" >> admin-openrc.sh
echo "export OS_IDENTITY_API_VERSION=3" >> admin-openrc.sh
echo "export OS_IMAGE_API_VERSION=2" >> admin-openrc.sh

#2.Edit the demo-openrc file and add the following content:
touch demo-openrc.sh
echo "export OS_PROJECT_DOMAIN_NAME=default" >> demo-openrc.sh
echo "export OS_USER_DOMAIN_NAME=default" >> demo-openrc.sh
echo "export OS_PROJECT_NAME=demo" >> demo-openrc.sh
echo "export OS_USERNAME=demo" >> demo-openrc.sh
echo "export OS_PASSWORD=$PASSWORD" >> demo-openrc.sh
echo "export OS_AUTH_URL=http://$C_IP:5000/v3" >> demo-openrc.sh
echo "export OS_IDENTITY_API_VERSION=3" >> demo-openrc.sh
echo "export OS_IMAGE_API_VERSION=2" >> demo-openrc.sh


