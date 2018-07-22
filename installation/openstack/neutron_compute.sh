#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


M_IP=10.10.10.52
C_IP=10.10.20.201
D_IP=10.10.30.52
CTR_M_IP=10.10.10.51
CTR_C_IP=10.10.20.200
#RABBIT_PASS=secrete
PASSWORD=PASS
#ADMIN_TOKEN=ADMIN
#MAIL=jshan@nm.gist.ac.kr



sed -i "/#kernel.domainname = example.com/a\
net.ipv4.ip_forward=1\n\
net.ipv4.conf.all.rp_filter=0\n\
net.ipv4.conf.default.rp_filter=0\n\
net.bridge.bridge-nf-call-iptables=1\n\
net.bridge.bridge-nf-call-ip6tables=1" /etc/sysctl.conf




# Install and Configure Neutron Compute Node

#Install and configure components

#1.Install the packages:
sudo apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent


#•Edit the /etc/neutron/neutron.conf file and complete the following actions:
sed -i "s/#rpc_backend = rabbit/rpc_backend = rabbit/g" /etc/neutron/neutron.conf
sed -i "s/#auth_strategy = keystone/auth_strategy = keystone/g" /etc/neutron/neutron.conf
sed -i "s/#rabbit_host = localhost/rabbit_host = $CTR_C_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $PASSWORD/g" /etc/neutron/neutron.conf
sed -i "s/#auth_uri = <None>/auth _uri = http:\/\/$CTR_C_IP:5000\n\
auth_url = http:\/\/$CTR_C_IP:35357\n\
memcached_servers = $CTR_C_IP:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = neutron\n\
password = $PASSWORD/g" /etc/neutron/neutron.conf


#•Edit the /etc/nova/nova.conf file and complete the following actions:
#◦In the [neutron] section, configure access parameters:
sed -i "s/\[oslo_messaging_rabbit\]/[neutron]\n\
url = http:\/\/$CTR_C_IP:9696\n\
auth_url = http:\/\/$CTR_C_IP:35357\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = $PASSWORD\n\
service_metadata_proxy = True\n\
metadata_proxy_shared_secret = METADATA_SECRET\n\
\n\
[oslo_messaging_rabbit]/g" /etc/nova/nova.conf


#.In the l3_agent.ini file, configure the L3 agent:
sed -i "s/#interface_driver = <None>/interface_driver = openvswitch/g" /etc/neutron/l3_agent.ini
sed -i "s/#external_network_bridge = br-ex/external_network_bridge =/g" /etc/neutron/l3_agent.ini
sed -i "s/#agent_mode = legacy/agent_mode = dvr/g" /etc/neutron/l3_agent.ini


#.In the metadata_agent.ini file, configure the metadata agent:
sed -i "s/#nova_metadata_ip = 127.0.0.1/nova_metadata_ip = $CTR_C_IP/g" /etc/neutron/metadata_agent.ini
sed -i "s/#metadata_proxy_shared_secret =/metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/neutron/metadata_agent.ini


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


#Restart the Neutron service:
service nova-compute restart
service neutron-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-metadata-agent restart
