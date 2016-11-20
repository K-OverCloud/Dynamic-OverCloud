#!/bin/bash

update_package(){
	#This is installation for OpenStack Mitaka Release.

	#Add Repository and update
	apt-get install -y software-properties-common
	add-apt-repository -y cloud-archive:newton
	#apt-get install -y software-properties-common
	#add-apt-repository -y cloud-archive:mitaka
	apt-get update && apt-get -y upgrade

	#openstack client
	apt-get -y install python-openstackclient

	#reboot
}

install_env_software() {
	# Install & Configure MYSQL

	sudo debconf-set-selections <<< "mariadb-server mysql-server/root_password password $PASSWORD"
	sudo debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $PASSWORD"
	sudo apt-get -y install mariadb-server python-pymysql

	sudo touch /etc/mysql/mariadb.conf.d/99-openstack.cnf

	echo "[mysqld]" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
	echo "bind-address = $C_IP" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
	echo "default-storage-engine = innodb" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
	echo "innodb_file_per_table" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
	echo "max_connections  = 4096" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
	echo "collation-server = utf8_general_ci" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
	#echo "init-connect = 'SET NAMES utf8'" >> /etc/mysql/conf.d/mysqld_openstack.cnf
	echo "character-set-server = utf8" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf

	service mysql restart

	echo -e "$PASSWORD\nn\ny\ny\ny\ny" | mysql_secure_installation


	# Install & Configure MongoDB

	#sudo apt-get install -y mongodb-server mongodb-clients python-pymongo

	#sed -i "s/bind_ip = 127.0.0.1/bind_ip = $C_IP/g" /etc/mongodb.conf

	# By default, MongoDB Crete serveral 1 GB journal files in the /var/lib/mongodb/journal directory.
	# If you want to reduce the size of each journal file to 128 MB and limit total journal space consumption to 512 MB, assert the smallfiles key:
	# sed -i "s/journal=true/journal=true\n smallfiles=true/g" /etc/mongodb.conf

	#service mongodb restart


	# Intall & Configure RabbitMQ

	sudo apt-get install -y rabbitmq-server

	rabbitmqctl add_user openstack $PASSWORD
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"


	# Install & configure Memcached

	sudo apt-get install -y memcached python-memcache

	sed -i "s/127.0.0.1/$C_IP/g" /etc/memcached.conf

	service memcached restart
}

install_keystone(){
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
	  --bootstrap-public-url http://$M_IP:5000/v3/ \
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
}

install_glance(){
	# Install and Configure Glance Service


	#1.To create the database, complete these steps:
	cat << EOF | mysql -uroot -p$PASSWORD
	CREATE DATABASE glance;
	GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$PASSWORD';
	GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$PASSWORD';
	quit
EOF

	#2.Source the admin credentials to gain access to admin-only CLI commands:
	source admin-openrc.sh

	#3.To create the service credentials, complete these steps:
	#◦Create the glance user:
	openstack user create --domain default --password $PASSWORD glance

	#◦Add the admin role to the glance user and service project:
	openstack role add --project service --user glance admin

	#◦Create the glance service entity:
	openstack service create --name glance \
	  --description "OpenStack Image" image

	#4.Create the Image service API endpoints:
	openstack endpoint create --region RegionOne \
	  image public http://$M_IP:9292

	openstack endpoint create --region RegionOne \
	  image internal http://$C_IP:9292

	openstack endpoint create --region RegionOne \
	  image admin http://$C_IP:9292



	#Install and configure components

	#1.Install the packages:
	sudo apt-get install -y glance

	#2.Edit the /etc/glance/glance-api.conf file and complete the following actions:
	#◦In the [database] section, configure database access:
	sed -i "s/#connection = <None>/connection = mysql+pymysql:\/\/glance:$PASSWORD@$C_IP\/glance/g" /etc/glance/glance-api.conf

	#◦In the [keystone_authtoken] and [paste_deploy] sections, configure Identity service access:
	sed -i "s/#auth_uri = <None>/auth_uri = http:\/\/$C_IP:5000\n\
	auth_url = http:\/\/$C_IP:35357\n\
	memcached_servers = $C_IP:11211\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	project_name = service\n\
	username = glance\n\
	password = $PASSWORD\n/g" /etc/glance/glance-api.conf

	sed -i "s/#flavor = keystone/flavor = keystone/g" /etc/glance/glance-api.conf

	#◦In the [glance_store] section, configure the local file system store and location of image files:
	sed -i "s/#stores = file,http/stores = file,http/g" /etc/glance/glance-api.conf
	sed -i "s/#default_store = file/default_store = file/g" /etc/glance/glance-api.conf
	sed -i "s/#filesystem_store_datadir = \/var\/lib\/glance\/images/filesystem_store_datadir = \/var\/lib\/glance\/images/g" /etc/glance/glance-api.conf


	#3.Edit the /etc/glance/glance-registry.conf file and complete the following actions:
	#◦In the [database] section, configure database access:
	sed -i "s/#connection = <None>/connection = mysql+pymysql:\/\/glance:$PASSWORD@$C_IP\/glance/g" /etc/glance/glance-registry.conf

	#◦In the [keystone_authtoken] and [paste_deploy] sections, configure Identity service access:
	sed -i "s/#auth_uri = <None>/auth_uri = http:\/\/$C_IP:5000\n\
	auth_url = http:\/\/$C_IP:35357\n\
	memcached_servers = $C_IP:11211\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	project_name = service\n\
	username = glance\n\
	password = $PASSWORD\n/g" /etc/glance/glance-registry.conf

	sed -i "s/#flavor = keystone/flavor = keystone/g" /etc/glance/glance-registry.conf


	#4.Populate the Image service database:
	su -s /bin/sh -c "glance-manage db_sync" glance

	# Restart the Image services:
	service glance-registry restart
	service glance-api restart



	# Download the source image:
	wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

	# Upload the image to the Image service using the QCOW2 disk format, bare container format, and public visibility so all projects can access it:
	openstack image create "cirros" \
	  --file cirros-0.3.4-x86_64-disk.img \
	  --disk-format qcow2 --container-format bare \
	  --public
}

install_nova(){
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
	  compute public http://$M_IP:8774/v2.1/%\(tenant_id\)s

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
}

install_neutron_wo_dvr(){
	#This part installs neutron with disabling DVR capability.
	sed -i "/#kernel.domainname = example.com/a\
	net.ipv4.ip_forward=1\n\
	net.ipv4.conf.all.rp_filter=0\n\
	net.ipv4.conf.default.rp_filter=0" /etc/sysctl.conf

	#1.To create the database, complete these steps:
	cat << EOF | mysql -uroot -p$PASSWORD
	CREATE DATABASE neutron;
	GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$PASSWORD';
	GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$PASSWORD';
	quit
EOF

	#2.Source the admin credentials to gain access to admin-only CLI commands:
	source admin-openrc.sh

	#3.To create the service credentials, complete these steps:
	#◦Create the neutron user:
	openstack user create --domain default --password $PASSWORD neutron

	#◦Add the admin role to the neutron user:
	openstack role add --project service --user neutron admin

	#◦Create the neutron service entity:
	openstack service create --name neutron \
	  --description "OpenStack Networking" network


	#4.Create the Networking service API endpoints:
	openstack endpoint create --region RegionOne \
	  network public http://$C_IP:9696

	openstack endpoint create --region RegionOne \
	  network internal http://$C_IP:9696

	openstack endpoint create --region RegionOne \
	  network admin http://$C_IP:9696


	#Install the components
	sudo apt-get install -y neutron-server neutron-plugin-ml2 \
	  neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
	  neutron-metadata-agent



	##•Edit the /etc/neutron/neutron.conf file and complete the following actions:
	sed -i "s/connection = sqlite:\/\/\/\/var\/lib\/neutron\/neutron.sqlite/connection = mysql+pymysql:\/\/neutron:$PASSWORD@$C_IP\/neutron/g" /etc/neutron/neutron.conf

	sed -i "s/#service_plugins =/service_plugins = router\n\
	allow_overlapping_ips = True\n\
	rpc_backend = rabbit\n\
	auth_strategy = keystone\n\
	notify_nova_on_port_status_changes = True\n\
	notify_nova_on_port_data_changes = True\n\
	router_distributed = True/g" /etc/neutron/neutron.conf

	sed -i "s/#rabbit_host = localhost/rabbit_host = $C_IP\n\
	rabbit_userid = openstack\n\
	rabbit_password = $PASSWORD/g" /etc/neutron/neutron.conf

	sed -i "s/#auth_uri = <None>/auth_uri = http:\/\/$C_IP:5000\n\
	auth_url = http:\/\/$C_IP:35357\n\
	memcached_servers = $C_IP:11211\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	project_name = service\n\
	username = neutron\n\
	password = $PASSWORD/g" /etc/neutron/neutron.conf

	sed -i "s/#auth_url = <None>/auth_url = http:\/\/$C_IP:35357\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	region_name = RegionOne\n\
	project_name = service\n\
	username = nova\n\
	password = $PASSWORD/g" /etc/neutron/neutron.conf


	#•Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:
	sed -i "s/#type_drivers = local,flat,vlan,gre,vxlan,geneve/type_drivers = vxlan\n\
	tenant_network_types = vxlan\n\
	mechanism_drivers = openvswitch,l2population\n\
	extension_drivers = port_security/g" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -i "s/#vxlan_group = <None>/#vxlan_group = <None>\n\
	vni_ranges = 1:1000/g" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -i "s/#flat_networks = \*/flat_networks = external/g" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\
	enable_ipset = True/g" /etc/neutron/plugins/ml2/ml2_conf.ini


	#.In the openvswitch_agent.ini file, configure the Open vSwitch agent:
	sed -i "s/#local_ip = <None>/local_ip = $D_IP/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#tunnel_types =/tunnel_types = vxlan\n\
	l2_population = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\
	enable_security_group = true/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#arp_responder = false/arp_responder = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#enable_distributed_routing = false/enable_distributed_routing = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	#.In the l3_agent.ini file, configure the L3 agent:
	sed -i "s/#interface_driver = <None>/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/g" /etc/neutron/l3_agent.ini

	sed -i "s/#external_network_bridge = br-ex/external_network_bridge = br-ex/g" /etc/neutron/l3_agent.ini

	sed -i "s/#agent_mode = legacy/agent_mode = dvr_snat/g" /etc/neutron/l3_agent.ini


	#.In the dhcp_agent.ini file, configure the DHCP agent:
	sed -i "s/#enable_isolated_metadata = false/enable_isolated_metadata = True/g" /etc/neutron/dhcp_agent.ini

	sed -i "s/#interface_driver = <None>/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/g" /etc/neutron/dhcp_agent.ini

	touch /etc/neutron/dnsmasq-neutron.conf
	echo "dhcp-option-force=26,1400" >> /etc/neutron/dnsmasq-neutron.conf

	sed -i "s/#dnsmasq_config_file =/dnsmasq_config_file = \/etc\/neutron\/dnsmasq-neutron.conf/g" /etc/neutron/dhcp_agent.ini

	pkill dnsmasq


	#.In the metadata_agent.ini file, configure the metadata agent:
	sed -i "s/#nova_metadata_ip = 127.0.0.1/nova_metadata_ip = $C_IP/g" /etc/neutron/metadata_agent.ini

	sed -i "s/#metadata_proxy_shared_secret =/metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/neutron/metadata_agent.ini


	#•Edit the /etc/nova/nova.conf file and complete the following actions:
	#◦In the [neutron] section, configure access parameters:
	sed -i "s/auth_strategy = keystone/auth_strategy = keystone\n\
	\n\
	[neutron]\n\
	url = http:\/\/$C_IP:9696\n\
	auth_url = http:\/\/$C_IP:35357\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	region_name = RegionOne\n\
	project_name = service\n\
	username = neutron\n\
	password = $PASSWORD\n\
	service_metadata_proxy = True\n\
	metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/nova/nova.conf


	#Finalize installation
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


	#Restart the Compute service:
	service nova-api restart
	service neutron-server restart
	service openvswitch-switch restart
	service neutron-openvswitch-agent restart
	service neutron-l3-agent restart
	service neutron-dhcp-agent restart
	service neutron-metadata-agent restart
}

install_neutron_w_dvr(){
	sed -i "/#kernel.domainname = example.com/a\
	net.ipv4.ip_forward=1\n\
	net.ipv4.conf.all.rp_filter=0\n\
	net.ipv4.conf.default.rp_filter=0" /etc/sysctl.conf

	#1.To create the database, complete these steps:
	cat << EOF | mysql -uroot -p$PASSWORD
	CREATE DATABASE neutron;
	GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$PASSWORD';
	GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$PASSWORD';
	quit
EOF

	#2.Source the admin credentials to gain access to admin-only CLI commands:
	source admin-openrc.sh

	#3.To create the service credentials, complete these steps:
	#◦Create the neutron user:
	openstack user create --domain default --password $PASSWORD neutron

	#◦Add the admin role to the neutron user:
	openstack role add --project service --user neutron admin

	#◦Create the neutron service entity:
	openstack service create --name neutron \
	  --description "OpenStack Networking" network


	#4.Create the Networking service API endpoints:
	openstack endpoint create --region RegionOne \
	  network public http://$M_IP:9696

	openstack endpoint create --region RegionOne \
	  network internal http://$C_IP:9696

	openstack endpoint create --region RegionOne \
	  network admin http://$C_IP:9696


	#Install the components
	sudo apt-get install -y neutron-server neutron-plugin-ml2 \
	  neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
	  neutron-metadata-agent



	##•Edit the /etc/neutron/neutron.conf file and complete the following actions:
	sed -i "s/connection = sqlite:\/\/\/\/var\/lib\/neutron\/neutron.sqlite/connection = mysql+pymysql:\/\/neutron:$PASSWORD@$C_IP\/neutron/g" /etc/neutron/neutron.conf

	sed -i "s/#service_plugins =/service_plugins = router\n\
	allow_overlapping_ips = True\n\
	rpc_backend = rabbit\n\
	auth_strategy = keystone\n\
	notify_nova_on_port_status_changes = True\n\
	notify_nova_on_port_data_changes = True\n\
	router_distributed = True/g" /etc/neutron/neutron.conf

	sed -i "s/#rabbit_host = localhost/rabbit_host = $C_IP\n\
	rabbit_userid = openstack\n\
	rabbit_password = $PASSWORD/g" /etc/neutron/neutron.conf

	sed -i "s/#auth_uri = <None>/auth_uri = http:\/\/$C_IP:5000\n\
	auth_url = http:\/\/$C_IP:35357\n\
	memcached_servers = $C_IP:11211\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	project_name = service\n\
	username = neutron\n\
	password = $PASSWORD/g" /etc/neutron/neutron.conf

	sed -i "s/#auth_url = <None>/auth_url = http:\/\/$C_IP:35357\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	region_name = RegionOne\n\
	project_name = service\n\
	username = nova\n\
	password = $PASSWORD/g" /etc/neutron/neutron.conf


	#•Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:
	sed -i "s/#type_drivers = local,flat,vlan,gre,vxlan,geneve/type_drivers = flat,vxlan\n\
	tenant_network_types = vxlan\n\
	mechanism_drivers = openvswitch,l2population\n\
	extension_drivers = port_security/g" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -i "s/#vxlan_group = <None>/#vxlan_group = <None>\n\
	vni_ranges = 1:1000/g" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -i "s/#flat_networks = \*/flat_networks = external/g" /etc/neutron/plugins/ml2/ml2_conf.ini

	sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\
	enable_ipset = True/g" /etc/neutron/plugins/ml2/ml2_conf.ini


	#.In the openvswitch_agent.ini file, configure the Open vSwitch agent:
	sed -i "s/#local_ip = <None>/local_ip = $D_IP/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#tunnel_types =/tunnel_types = vxlan\n\
	l2_population = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\
	enable_security_group = true/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#arp_responder = false/arp_responder = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#enable_distributed_routing = false/enable_distributed_routing = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

	sed -i "s/#bridge_mappings =/bridge_mappings = external:br-ex/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini



	#.In the l3_agent.ini file, configure the L3 agent:
	sed -i "s/#interface_driver = <None>/interface_driver = openvswitch/g" /etc/neutron/l3_agent.ini

	sed -i "s/#external_network_bridge = br-ex/external_network_bridge = /g" /etc/neutron/l3_agent.ini

	sed -i "s/#agent_mode = legacy/agent_mode = dvr_snat/g" /etc/neutron/l3_agent.ini


	#.In the dhcp_agent.ini file, configure the DHCP agent:
	sed -i "s/#enable_isolated_metadata = false/enable_isolated_metadata = True/g" /etc/neutron/dhcp_agent.ini

	sed -i "s/#interface_driver = <None>/interface_driver = openvswitch/g" /etc/neutron/dhcp_agent.ini

	touch /etc/neutron/dnsmasq-neutron.conf
	echo "dhcp-option-force=26,1400" >> /etc/neutron/dnsmasq-neutron.conf

	sed -i "s/#dnsmasq_config_file =/dnsmasq_config_file = \/etc\/neutron\/dnsmasq-neutron.conf/g" /etc/neutron/dhcp_agent.ini

	pkill dnsmasq


	#.In the metadata_agent.ini file, configure the metadata agent:
	sed -i "s/#nova_metadata_ip = 127.0.0.1/nova_metadata_ip = $C_IP/g" /etc/neutron/metadata_agent.ini

	sed -i "s/#metadata_proxy_shared_secret =/metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/neutron/metadata_agent.ini


	#•Edit the /etc/nova/nova.conf file and complete the following actions:
	#◦In the [neutron] section, configure access parameters:
	sed -i "s/auth_strategy = keystone/auth_strategy = keystone\n\
	\n\
	[neutron]\n\
	url = http:\/\/$C_IP:9696\n\
	auth_url = http:\/\/$C_IP:35357\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	region_name = RegionOne\n\
	project_name = service\n\
	username = neutron\n\
	password = $PASSWORD\n\
	service_metadata_proxy = True\n\
	metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/nova/nova.conf


	#Finalize installation
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


	#Restart the Compute service:
	service nova-api restart
	service neutron-server restart
	service openvswitch-switch restart
	service neutron-openvswitch-agent restart
	service neutron-l3-agent restart
	service neutron-dhcp-agent restart
	service neutron-metadata-agent restart
}

configure_ovs(){
	INTERFACE=br-ex

	ovs-vsctl add-br br-ex
	ifconfig $INTERFACE 0
	ovs-vsctl add-port br-ex $INTERFACE

	sed -i "s/$INTERFACE/br-ex/g" /etc/network/interfaces
	sed -i "s/loopback/loopback\n\n\
	auto $INTERFACE/g" /etc/network/interfaces

	echo "this is end for ethernet setting"

	ifdown br-ex
	ifup br-ex
	ifconfig $INTERFACE up
}

install_horizon(){
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

}

install_heat(){
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

	#Create the heat user:
	openstack user create --domain default --password $PASSWORD heat

	#Add the admin role to the heat user:
	openstack role add --project service --user heat admin

	#Create the heat and heat-cfn service entities:
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

	#Create the heat domain that contains projects and users for stacks:
	openstack domain create --description "Stack projects and users" heat

	#Create the heat_domain_admin user to manage projects and users in the heat domain:
	openstack user create --domain heat --password $PASSWORD heat_domain_admin

	#Add the admin role to the heat_domain_admin user in the heat domain to enable administrative stack management privileges by the heat_domain_admin user:
	openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

	#Create the heat_stack_owner role:
	openstack role create heat_stack_owner

	#Add the heat_stack_owner role to the demo project and user to enable stack management by the demo user:
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

	sed -i "s/#auth_uri = <None>/auth_uri = http:\/\/$C_IP:5000\n\
	auth_url = http:\/\/$C_IP:35357\n\
	memcached_servers = $C_IP:11211\n\
	auth_type = password\n\
	project_domain_name = default\n\
	user_domain_name = default\n\
	project_name = service\n\
	username = heat\n\
	password = $PASSWORD/g" /etc/heat/heat.conf


	sed -i "s/#auth_type = <None>/\[trustee\]\n\
	auth_plugin = password\n\
	auth_url = http:\/\/$C_IP:35357\n\
	username = heat\n\
	password = $PASSWORD\n\
	user_domain_name = default\n\
	\n\
	[clients_keystone]\n\
	auth_uri = http:\/\/$C_IP:35357\n\
	\n\
	[ec2authtoken]\n\
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
}

M_IP=<M_IP>
C_IP=<C_IP>
D_IP=<D_IP>
#RABBIT_PASS=secrete
PASSWORD=<PASSWORD>
#ADMIN_TOKEN=ADMIN
#MAIL=jshan@nm.gist.ac.kr
#SERVICES="keystone glance nova neutron horizon"

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

update_package
install_env_software
install_keystone
install_glance
install_nova
install_neutron_w_dvr
install_horizon
