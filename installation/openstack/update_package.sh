
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



